<p align="center">
<img src="https://github.com/crowdsecurity/cs-nginx-bouncer/raw/main/docs/assets/crowdsec_nginx.png" alt="CrowdSec" title="CrowdSec" width="280" height="300" />
</p>
<p align="center">
<img src="https://img.shields.io/badge/build-pass-green">
<img src="https://img.shields.io/badge/tests-pass-green">
</p>
<p align="center">
&#x1F4DA; <a href="#installation/">Documentation</a>
&#x1F4A0; <a href="https://hub.crowdsec.net">Hub</a>
&#128172; <a href="https://discourse.crowdsec.net">Discourse </a>
</p>



# CrowdSec NGINX Bouncer

A lua bouncer for nginx.

## How does it work ?

This bouncer leverages nginx lua's API, namely `access_by_lua_file`.

New/unknown IP are checked against crowdsec API, and if request should be blocked, a **403** is returned to the user, and put in cache.

At the back, this bouncer uses [crowdsec lua lib](https://github.com/crowdsecurity/lua-cs-bouncer/).

# Installation

## Install script

Download the latest release [here](https://github.com/crowdsecurity/cs-nginx-bouncer/releases)

```bash
tar xvzf cs-nginx-bouncer.tgz
cd cs-nginx-bouncer-v*/
sudo ./install.sh
```

If you are on a mono-machine setup, the `cs-nginx-bouncer` install script will register directly to the local crowdsec, so you're good to go !

## Upgrade script

## Upgrade

If you already have `cs-nginx-bouncer` installed, please download the [latest release](https://github.com/crowdsecurity/cs-nginx-bouncer/releases) and run the following commands:

```bash
tar xzvf cs-nginx-bouncer.tgz
cd cs-nginx-bouncer-v*/
sudo ./upgrade.sh
sudo systemctl restart nginx
```

## Configuration

If your nginx bouncer needs to comunicate with a remote crowdsec API, you can configure API url and key in `/etc/crowdsec/cs-nginx-bouncer/crowdsec.conf`:

```lua
API_URL=http://127.0.0.1:8080
API_KEY=<API KEY> --generated with `cscli bouncers add -n <bouncer_name>
LOG_FILE=/tmp/lua_mod.log
CACHE_EXPIRATION=1
CACHE_SIZE=1000
```

Then restart nginx:

```sh
sudo systemctl restart nginx
```

:warning: the installation script will take care of dependencies for Debian/Ubuntu
<details>
  <summary>non-debian based dependencies</summary>

  - libnginx-mod-http-lua : nginx lua support
  - lua-sec : for https client request
</details>


## From source

### Requirements

The following packages are required :

- lua
- lua-sec
- libnginx-mod-http-lua

#### Debian/Ubuntu

```bash
sudo apt-get install lua5.3 libnginx-mod-http-lua lua-sec
```

Download the following 2 repositories:

- [`lua-cs-bouncer`](https://github.com/crowdsecurity/lua-cs-bouncer):
```bash
git clone https://github.com/crowdsecurity/lua-cs-bouncer.git
```

- [`cs-nginx-bouncer`](https://github.com/crowdsecurity/cs-nginx-bouncer)
```bash
git clone https://github.com/crowdsecurity/cs-nginx-bouncer.git
```

### Installation

#### lua-cs-bouncer

```bash
cd ./lua-cs-bouncer/
sudo make install
```

#### cs-nginx-bouncer

- Copy the `cs-nginx-bouncer/nginx/crowdsec_nginx.conf` into `/etc/nginx/conf.d/crowdsec_nginx.conf`:
```bash
cp ./cs-nginx-bouncer/nginx/crowdsec_nginx.conf /etc/nginx/conf.d/crowdsec_nginx.conf
```
- Copy the `cs-nginx-bouncer/nginx/access.lua` into `/usr/local/lua/crowdec/access.lua`:
```bash
cp ./cs-nginx-bouncer/nginx/access.lua /usr/local/lua/crowdec/access.lua
```

Configure your API url and key in `/etc/crowdsec/cs-nginx-bouncer/crowdsec.conf`:

```lua
API_URL=http://127.0.0.1:8080
API_KEY=<API KEY> --generated with `cscli bouncers add -n <bouncer_name>
LOG_FILE=/tmp/lua_mod.log
CACHE_EXPIRATION=1
CACHE_SIZE=1000
```

You can now restart your nginx server:
```bash
systemctl restart nginx
```


# Configuration

The configuration file loaded by nginx is `/etc/nginx/conf.d/crowdsec_nginx.conf`, but you shouldn't have to edit it, the relevant configuration file being `/etc/crowdsec/cs-nginx-bouncer/crowdsec.conf` :

```bash
API_URL=http://localhost:8080                 <-- the API url
API_KEY=                                      <-- the API Key generated with `cscli bouncers add -n <bouncer_name>` 
LOG_FILE=/tmp/lua_mod.log                     <-- path to log file
CACHE_EXPIRATION=1                            <-- in seconds : how often is the yes/no decisions for an IP refreshed
CACHE_SIZE=1000                               <-- cache size : how many simulatenous entries are kept in 
```

# How it works

 - deploys `/etc/nginx/conf.d/crowdsec_nginx.conf` with `access_by_lua` directive
 - deploys `/usr/local/lua/crowdsec/access.lua` with the lua code checking incoming IPs against crowdsec API

# Testing

When your IP is blocked, any request should lead to a `403` http response.
