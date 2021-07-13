#!/bin/bash

LUA_MOD_DIR="./lua-mod"
NGINX_CONF="crowdsec_nginx.conf"
NGINX_CONF_DIR="/etc/nginx/conf.d/"
ACCESS_FILE="access.lua"
LIB_PATH="/usr/local/lua/crowdsec/"
CONFIG_PATH="/etc/crowdsec/bouncers/"
CONFIG_FILE="${CONFIG_PATH}crowdsec-nginx-bouncer.conf"
OLD_CONFIG_FILE="/etc/crowdsec/crowdsec-nginx-bouncer.conf"

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

migrate_conf() {
    if [ -f "$CONFIG_FILE" ]; then
        return
    fi
    if [ ! -f "$OLD_CONFIG_FILE" ]; then
        return
    fi
    echo "Found $OLD_CONFIG_FILE, but no $CONFIG_FILE. Migrating it."
    mv "$OLD_CONFIG_FILE" "$CONFIG_FILE"
}

if ! [ $(id -u) = 0 ]; then
    log_err "Please run the upgrade script as root or with sudo"
    exit 1
fi

if [ ! -d "${CONFIG_PATH}" ]; then
    echo "crowdsec-nginx-bouncer is not installed, please run the ./install.sh script"
    exit 1
fi

requirement
install
migrate_conf
echo "crowdsec-nginx-bouncer upgraded successfully"