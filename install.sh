#!/bin/bash

LUA_MOD_DIR="./lua-mod"
NGINX_CONF="crowdsec_nginx.conf"
NGINX_CONF_DIR="/etc/nginx/conf.d/"
ACCESS_FILE="access.lua"
LIB_PATH="/usr/local/lua/crowdsec/"
CONFIG_PATH="/etc/crowdsec/bouncers/"
DATA_PATH="/var/lib/crowdsec/lua/"
LAPI_DEFAULT_PORT="8080"
SILENT="false"

#Accept cmdline arguments to overwrite options.
while [[ $# -gt 0 ]]
do
    case $1 in
        -y|--yes)
            SILENT="true"
        ;;
    esac
    shift
done

gen_apikey() {
    SUFFIX=`tr -dc A-Za-z0-9 </dev/urandom | head -c 8`
    API_KEY=`sudo cscli bouncers add crowdsec-nginx-bouncer-${SUFFIX} -o raw`
    PORT=$(cscli config show --key "Config.API.Server.ListenURI"|cut -d ":" -f2)
    if [ ! -z "$PORT" ]; then
       LAPI_DEFAULT_PORT=${PORT}
    fi
    CROWDSEC_LAPI_URL="http://127.0.0.1:${LAPI_DEFAULT_PORT}"
    mkdir -p "${CONFIG_PATH}"
    API_KEY=${API_KEY} CROWDSEC_LAPI_URL=${CROWDSEC_LAPI_URL} envsubst < ${LUA_MOD_DIR}/config_example.conf | sudo tee -a "${CONFIG_PATH}crowdsec-nginx-bouncer.conf" >/dev/null
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
            if [[ ${SILENT} == "true" ]]; then
                sudo apt-get install -y -qq ${dep} > /dev/null && echo "${dep} successfully installed"
            else
                echo "${dep} not found, do you want to install it (Y/n)? "
                read answer
                if [[ ${answer} == "" ]]; then
                    answer="y"
                fi
                if [ "$answer" != "${answer#[Yy]}" ] ;then
                    sudo apt-get install -y -qq ${dep} > /dev/null && echo "${dep} successfully installed"
                else
                    echo "unable to continue without ${dep}. Exiting" && exit 1
                fi
            fi
        fi
    done
}


install() {
    sudo mkdir -p ${LIB_PATH}/plugins/crowdsec/
    sudo mkdir -p ${DATA_PATH}/templates/

    sudo cp nginx/${NGINX_CONF} ${NGINX_CONF_DIR}/${NGINX_CONF}
    sudo cp -r ${LUA_MOD_DIR}/lib/* ${LIB_PATH}/
    sudo cp -r ${LUA_MOD_DIR}/templates/* ${DATA_PATH}/templates/

    sudo luarocks install lua-resty-http
    sudo luarocks install lua-cjson
}


check_nginx_dependency
gen_apikey
install

if command -v "$CSCLI" >/dev/null; then
    PORT=$(cscli config show --key "Config.API.Server.ListenURI"|cut -d ":" -f2)
    if [ ! -z "$PORT" ]; then
       sed -i "s/localhost:8080/localhost:${PORT}/g" /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml
    fi
fi

echo "crowdsec-nginx-bouncer installed successfully"