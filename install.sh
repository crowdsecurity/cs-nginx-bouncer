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
    mkdir -p "${CONFIG_PATH}"
    mkdir -p "${LIB_PATH}"
}

check_apikeygen() {
    echo "if you are on a single-machine setup, do you want the wizard to configure your API key ? (Y/n)"
    echo "(note: if you didn't understand the question, 'Y' might be a safe answer)"
    read answer
    if [[ ${answer} == "" ]]; then
            answer="y"
    fi
    if [ "$answer" != "${answer#[Yy]}" ] ;then
            SUFFIX=`tr -dc A-Za-z0-9 </dev/urandom | head -c 8`
            API_KEY=`cscli bouncers add cs-nginx-bouncer-${SUFFIX} -o raw`
            API_KEY=${API_KEY} envsubst < ./config/crowdsec.conf > "${CONFIG_PATH}crowdsec.conf"
    else 
        echo "For your bouncer to be functionnal, you need to create an API key and set it in the ${CONFIG_PATH}crowdsec.conf file"
    fi;
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


requirement
check_nginx_dependency
check_apikeygen
install