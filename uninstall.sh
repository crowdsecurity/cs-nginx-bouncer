#!/bin/bash

REQUIRE_SCRIPT="./lua-mod/uninstall.sh"
NGINX_CONF="crowdsec_nginx.conf"
NGINX_CONF_DIR="/etc/nginx/conf.d/"
ACCESS_FILE="access.lua"
LIB_PATH="/usr/local/lua/crowdsec/"


requirement() {
    if [ -f "$REQUIRE_SCRIPT" ]; then
        bash $REQUIRE_SCRIPT
    fi
}


remove_nginx_dependency() {
    DEPENDENCY=(
        "libnginx-mod-http-lua"
        "lua-logging"
    )
    for dep in ${DEPENDENCY[@]};
    do
        dpkg -l | grep ${dep} > /dev/null
        if [[ $? == 0 ]]; then
            echo "${dep} found, do you want to remove it (Y/n)? "
            read answer
            if [[ ${answer} == "" ]]; then
                answer="y"
            fi
            if [ "$answer" != "${answer#[Yy]}" ] ;then
                apt-get remove --purge -y -qq ${dep} > /dev/null && echo "${dep} successfully removed"
            fi      
        fi
    done
}


uninstall() {
	rm ${NGINX_CONF_DIR}/${NGINX_CONF}
}

if ! [ $(id -u) = 0 ]; then
    log_err "Please run the uninstall script as root or with sudo"
    exit 1
fi
requirement
remove_nginx_dependency
uninstall
echo "cs-nginx-bouncer uninstalled successfully"