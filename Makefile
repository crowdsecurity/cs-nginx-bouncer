BUILD_VERSION?="$(shell git for-each-ref --sort=-v:refname --count=1 --format '%(refname)'  | cut -d '/' -f3)"
OUTDIR="crowdsec-nginx-bouncer-${BUILD_VERSION}/"
LUA_MOD_DIR="${OUTDIR}lua-mod"
CONFIG_DIR="${OUTDIR}config"
OUT_ARCHIVE="crowdsec-nginx-bouncer.tgz"
LUA_BOUNCER_BRANCH?=v1.0.19
.PHONY: default release clean vendor-sync vendor-verify vendor-outdated
default: release
release: 
	git clone -b "${LUA_BOUNCER_BRANCH}" https://github.com/crowdsecurity/lua-cs-bouncer.git
	mkdir -p ${LUA_MOD_DIR}
	cp -r lua-cs-bouncer/* "${LUA_MOD_DIR}"/
	for dep in vendor/*/; do cp -r "$${dep}lib/"* "${LUA_MOD_DIR}/lib/"; done

	cp install.sh ${OUTDIR}
	chmod +x ${OUTDIR}install.sh

	cp uninstall.sh ${OUTDIR}
	chmod +x ${OUTDIR}uninstall.sh

	cp upgrade.sh ${OUTDIR}
	chmod +x ${OUTDIR}upgrade.sh

	cp -r ./nginx/ ${OUTDIR}
	tar cvzf ${OUT_ARCHIVE} ${OUTDIR}
	rm -rf ${OUTDIR}
	rm -rf "lua-cs-bouncer/"

vendor-sync:
	./scripts/vendor.sh sync

vendor-verify:
	./scripts/vendor.sh verify

vendor-outdated:
	./scripts/vendor.sh outdated

clean:
	rm -rf "${OUTDIR}"
	rm -rf "${OUT_ARCHIVE}"
	rm -rf "lua-cs-bouncer/"
