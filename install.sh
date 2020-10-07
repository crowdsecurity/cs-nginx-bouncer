#!/bin/bash

LUA_MOD_DIR="./lua-mod"
NGINX_CONF="crowdsec_nginx.conf"
NGINX_CONF_DIR="/etc/nginx/conf.d/"
ACCESS_FILE="access.lua"
LIB_PATH="/usr/local/lua/crowdsec/"


requirement() {
    cd $LUA_MOD_DIR
    bash "./install.sh"
    cd ..
}


check_nginx_dependency() {
    DEPENDENCY=(
        "libnginx-mod-http-lua"
    )
    for dep in ${DEPENDENCY[@]};
    do
        dpkg -l | grep ${dep} > /dev/null
        if [[ $? != 0 ]]; then
            echo "${dep} not found, do you want to install it (Y/n)? "
            read answer
            if [[ ${answer} == "" ]]; then
                answer="y"
            fi
            if [ "$answer" != "${answer#[Yy]}" ] ;then
                apt-get install -y -qq ${dep} > /dev/null && echo "${dep} successfully installed"
            else
                echo "unable to continue without ${dep}. Exiting" && exit 1
            fi      
        fi
    done
}


install() {
	cp nginx/${NGINX_CONF} ${NGINX_CONF_DIR}/${NGINX_CONF}
	cp nginx/${ACCESS_FILE} ${LIB_PATH}
}


requirement
check_nginx_dependency
install