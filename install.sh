#!/bin/bash

LUA_MOD_DIR="./lua-mod"
NGINX_CONF="crowdsec_nginx.conf"
NGINX_CONF_DIR="/etc/nginx/conf.d/"
ACCESS_FILE="access.lua"
LIB_PATH="/usr/local/lua/crowdsec/"
CONFIG_DIR="/etc/crowdsec/nginx-bouncer/"

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
    mkdir -p ${CONFIG_DIR}
	cp nginx/${NGINX_CONF} ${NGINX_CONF_DIR}/${NGINX_CONF}
	cp nginx/${ACCESS_FILE} ${LIB_PATH}
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
            API_KEY=`cscli bouncers add -n nginx-bouncer-${SUFFIX} -o raw`
            API_KEY=${API_KEY} envsubst < ./config/crowdsec.conf > "${CONFIG_DIR}crowdsec.conf"
    else 
        echo "For your bouncer to be functionnal, you need to create an API key and set it in the ${CONFIG_DIR}crowdsec.conf file"
    fi;
}

requirement
check_nginx_dependency
install
check_apikeygen