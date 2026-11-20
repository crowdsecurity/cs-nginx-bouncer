#!/bin/bash
#
# Smoke test of the bouncer on the distribution nginx.
#
# Builds the Debian package from this tree, installs it with its declared
# dependencies (nginx, libnginx-mod-http-lua, lua-cjson, ...) and checks that:
#   - nginx actually starts: `nginx -t` alone does not catch every Lua load error,
#   - every vendored Lua module can be required (catches a vendored dependency
#     needing a module that distributions do not ship, e.g. resty.string),
#   - a request goes through the bouncer.
#
# Meant to run as root in a throwaway Debian/Ubuntu container:
#   docker run --rm -v "$PWD:/src:ro" debian:12 /src/scripts/smoke-test.sh

set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
PORT=8081
ERROR_LOG=/var/log/nginx/error.log

fail() {
    echo "FAIL: $*" >&2
    echo "--- ${ERROR_LOG}" >&2
    cat "${ERROR_LOG}" >&2 || true
    exit 1
}

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq --no-install-recommends \
    build-essential ca-certificates curl debhelper git patch > /dev/null

# Build the package from a copy, the source tree may be read-only.
BUILD="$(mktemp -d)"
cp -a "${SRC}" "${BUILD}/src"
cd "${BUILD}/src"
rm -rf lua-cs-bouncer
# There is no debian/source/format, so dpkg-buildpackage does not apply
# debian/patches by itself: do it like the packaging pipeline does.
while read -r patch _; do
    patch -s -p1 < "debian/patches/${patch}"
done < debian/patches/series
dpkg-buildpackage -us -uc -b > "${BUILD}/build.log" 2>&1 || { cat "${BUILD}/build.log"; exit 1; }

# Installing the .deb with apt pulls the declared dependencies: anything the
# bouncer needs at runtime must come either from them or from vendor/.
apt-get install -y -qq "${BUILD}"/crowdsec-nginx-bouncer_*_all.deb > /dev/null

# No LAPI in the container: point the bouncer at a closed port, it fails open.
sed -i -e 's|^API_URL=.*|API_URL=http://127.0.0.1:8080|' \
       -e 's|^API_KEY=.*|API_KEY=smoke-test|' \
    /etc/crowdsec/bouncers/crowdsec-nginx-bouncer.conf

# Every vendored module, as a Lua table of module names.
modules=$(cd "${SRC}/vendor" && find . -path '*/lib/*.lua' \
    | sed -e 's|^\./[^/]*/lib/||' -e 's|\.lua$||' -e 's|/|.|g' | sort \
    | sed -e 's|.*|"&",|' | tr -d '\n')
echo "vendored modules: ${modules}"

cat > /etc/nginx/conf.d/zz-smoke-test.conf <<EOF
server {
    listen 127.0.0.1:${PORT};
    location = /require {
        default_type text/plain;
        content_by_lua_block {
            local failed = {}
            for _, name in ipairs({ "crowdsec", ${modules} }) do
                local ok, err = pcall(require, name)
                if not ok then
                    table.insert(failed, name .. ": " .. tostring(err))
                end
            end
            if #failed > 0 then
                ngx.status = 500
                ngx.say(table.concat(failed, "\n"))
                return
            end
            ngx.say("ok")
        }
    }
    location / {
        return 200 "ok\n";
    }
}
EOF

nginx -t || fail "nginx -t"
nginx || fail "nginx did not start"
sleep 2
kill -0 "$(cat /run/nginx.pid 2> /dev/null)" 2> /dev/null || fail "nginx is not running"

body=$(curl -sS -w '\n%{http_code}' "http://127.0.0.1:${PORT}/require") || fail "request to /require"
[ "${body##*$'\n'}" = 200 ] || fail "some vendored modules cannot be loaded:"$'\n'"${body%$'\n'*}"
echo "all vendored modules load"

code=$(curl -sS -o /dev/null -w '%{http_code}' "http://127.0.0.1:${PORT}/") || fail "request through the bouncer"
[ "${code}" = 200 ] || fail "request through the bouncer returned ${code}"
echo "request through the bouncer: ${code}"

# The LAPI is unreachable on purpose: only those errors are expected.
if grep -E '\[(error|crit|alert|emerg)\]|lua entry thread aborted' "${ERROR_LOG}" \
    | grep -vE 'Connection refused|connection refused|failed to query LAPI|bouncer error|\[Crowdsec\] Initialisation done|no recaptcha site key|captcha'; then
    fail "unexpected errors in ${ERROR_LOG}"
fi

nginx -s quit
echo "smoke test passed"
