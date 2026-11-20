<p align="center">
<img src="https://github.com/crowdsecurity/cs-nginx-bouncer/raw/main/docs/assets/crowdsec_nginx.svg" alt="CrowdSec" title="CrowdSec" width="280" height="300" />
</p>
<p align="center">
<img src="https://img.shields.io/badge/build-pass-green">
<img src="https://img.shields.io/badge/tests-pass-green">
</p>
<p align="center">
&#x1F4DA; <a href="#installation">Documentation</a>
&#x1F4A0; <a href="https://hub.crowdsec.net">Hub</a>
&#128172; <a href="https://discourse.crowdsec.net">Discourse </a>
</p>



# CrowdSec NGINX Bouncer

A lua bouncer for nginx.

## How does it work ?

This bouncer leverages nginx lua's API, namely `access_by_lua_file`.

New/unknown IP are checked against crowdsec API, and if request should be blocked, a **403** is returned to the user, and put in cache.

At the back, this bouncer uses [crowdsec lua lib](https://github.com/crowdsecurity/lua-cs-bouncer/).

# Installation

Please follow the [official documentation](https://doc.crowdsec.net/docs/bouncers/nginx).


# Vendored dependencies

Pure-Lua dependencies (currently `lua-resty-http` and `lua-resty-string`, which `lua-resty-http` requires and distributions do not package) are vendored under `vendor/` and shipped with the bouncer, pinned by tag and commit in `vendor/vendor.conf`. `lua-cjson` is a C module and comes from the distribution package.

```sh
./scripts/vendor.sh list                          # pinned versions
./scripts/vendor.sh outdated                      # newer upstream tags
./scripts/vendor.sh update lua-resty-http [tag]   # bump (default: latest tag)
./scripts/vendor.sh verify                        # vendor/ matches upstream
./scripts/vendor.sh advisories                    # upstream security advisories (needs gh)
```

The `vendored-dependencies` workflow runs weekly, opens a PR for each outdated dependency and reports upstream security advisories.

The `smoke-test` workflow builds the Debian package, installs it on the distribution nginx (Debian 12/13, Ubuntu 24.04) and checks that nginx starts and every vendored module loads, so a bump needing a module distributions do not ship fails the PR. Run it locally with:

```sh
docker run --rm -v "$PWD:/src:ro" debian:12 /src/scripts/smoke-test.sh
```
