#!/bin/bash

LUA_MOD_DIR="./lua-mod"
NGINX_CONF="crowdsec_nginx.conf"
NGINX_CONF_DIR="/etc/nginx/conf.d/"
ACCESS_FILE="access.lua"
LIB_PATH="/usr/local/lua/crowdsec/"
CONFIG_PATH="/etc/crowdsec/bouncers/"

gen_apikey() {
    SUFFIX=`tr -dc A-Za-z0-9 </dev/urandom | head -c 8`
    API_KEY=`cscli bouncers add crowdsec-nginx-bouncer-${SUFFIX} -o raw`
    CROWDSEC_LAPI_URL="http://127.0.0.1:8080"
    mkdir -p "${CONFIG_PATH}"
    API_KEY=${API_KEY} CROWDSEC_LAPI_URL=${CROWDSEC_LAPI_URL} envsubst < ${LUA_MOD_DIR}/nginx/template.conf > "${CONFIG_PATH}crowdsec-nginx-bouncer.conf"
}

check_nginx_dependency() {
    DEPENDENCY=(
        "libnginx-mod-http-lua"
        "luarocks"
        "lua5.1"
        "gettext-base"
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
    mkdir -p ${LIB_PATH}/plugins/crowdsec/
    mkdir -p ${LIB_PATH}/templates/

	cp nginx/${NGINX_CONF} ${NGINX_CONF_DIR}/${NGINX_CONF}
    cp ${LUA_MOD_DIR}/nginx/config.lua ${LIB_PATH}/plugins/crowdsec/
    cp ${LUA_MOD_DIR}/nginx/crowdsec.lua ${LIB_PATH}
    cp ${LUA_MOD_DIR}/nginx/recaptcha.lua ${LIB_PATH}/plugins/crowdsec/
    cp ${LUA_MOD_DIR}/nginx/iputils.lua ${LIB_PATH}/plugins/crowdsec/
    cp ${LUA_MOD_DIR}/nginx/bitop.lua ${LIB_PATH}/plugins/crowdsec/
    cp ${LUA_MOD_DIR}/nginx/utils.lua ${LIB_PATH}/plugins/crowdsec/
    cp ${LUA_MOD_DIR}/nginx/template.lua ${LIB_PATH}/plugins/crowdsec/
    cp ${LUA_MOD_DIR}/nginx/ban.lua ${LIB_PATH}/plugins/crowdsec/

    cp ${LUA_MOD_DIR}/nginx/templates/captcha.html ${LIB_PATH}/templates/
    cp ${LUA_MOD_DIR}/nginx/templates/ban.html ${LIB_PATH}/templates/

    luarocks install lua-resty-http
    luarocks install lua-cjson
}


if ! [ $(id -u) = 0 ]; then
    log_err "Please run the install script as root or with sudo"
    exit 1
fi

check_nginx_dependency
gen_apikey
install
echo "crowdsec-nginx-bouncer installed successfully"