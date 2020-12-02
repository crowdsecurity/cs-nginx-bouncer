#!/bin/bash

LUA_MOD_DIR="./lua-mod"
NGINX_CONF="crowdsec_nginx.conf"
NGINX_CONF_DIR="/etc/nginx/conf.d/"
ACCESS_FILE="access.lua"
LIB_PATH="/usr/local/lua/crowdsec/"
CONFIG_PATH="/etc/crowdsec/cs-nginx-bouncer/"

requirement() {
    cd $LUA_MOD_DIR
    bash "./install.sh"
    cd ..
    mkdir -p "${LIB_PATH}"
}

install() {
	cp nginx/${NGINX_CONF} ${NGINX_CONF_DIR}/${NGINX_CONF}
	cp nginx/${ACCESS_FILE} ${LIB_PATH}
}

if ! [ $(id -u) = 0 ]; then
    log_err "Please run the upgrade script as root or with sudo"
    exit 1
fi

if [ ! -d "${CONFIG_PATH}" ]; then
    echo "cs-nginx-bouncer is not installed, please run the ./install.sh script"
    exit 1
fi

requirement
install
echo "cs-nginx-bouncer upgraded successfully"