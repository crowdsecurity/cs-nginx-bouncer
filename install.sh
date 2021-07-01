#!/bin/bash

LUA_MOD_DIR="./lua-mod"
NGINX_CONF="crowdsec_nginx.conf"
NGINX_CONF_DIR="/etc/nginx/conf.d/"
ACCESS_FILE="access.lua"
LIB_PATH="/usr/local/lua/crowdsec/"
CONFIG_PATH="/etc/crowdsec/bouncers/"

requirement() {
    cd $LUA_MOD_DIR
    bash "./install.sh"
    cd ..
    mkdir -p "${CONFIG_PATH}"
    mkdir -p "${LIB_PATH}"
}

gen_apikey() {
    SUFFIX=`tr -dc A-Za-z0-9 </dev/urandom | head -c 8`
    API_KEY=`cscli bouncers add crowdsec-nginx-bouncer-${SUFFIX} -o raw`
    API_KEY=${API_KEY} envsubst < ./config/crowdsec.conf > "${CONFIG_PATH}crowdsec-nginx-bouncer.conf"
}

check_nginx_dependency() {
    DEPENDENCY=(
        "libnginx-mod-http-lua"
        "lua-logging"
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


if ! [ $(id -u) = 0 ]; then
    log_err "Please run the install script as root or with sudo"
    exit 1
fi
requirement
check_nginx_dependency
gen_apikey
install
echo "crowdsec-nginx-bouncer installed successfully"