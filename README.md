<p align="center">
<img src="https://github.com/crowdsecurity/cs-nginx-blocker/raw/master/docs/assets/crowdsec_nginx_logo.png" alt="CrowdSec" title="CrowdSec" width="280" height="400" />
</p>
<p align="center">
<img src="https://img.shields.io/badge/build-pass-green">
<img src="https://img.shields.io/badge/tests-pass-green">
</p>
<p align="center">
&#x1F4DA; <a href="https://docs.crowdsec.net/blockers/nginx/installation/">Documentation</a>
&#x1F4A0; <a href="https://hub.crowdsec.net">Hub</a>
&#128172; <a href="https://discourse.crowdsec.net">Discourse </a>
</p>



# CrowdSec NGINX Blocker

A lua blocker for nginx.

## How does it work ?

This blocker leverages nginx lua's API, namely `access_by_lua_file`.

New/unknown IP are checked against crowdsec's database, and if request should be blocked, a **403** is returned to the user, and put in cache.

At the back, this blocker uses [crowdsec lua lib](https://github.com/crowdsecurity/cs-lua-lib/).

# Installation

## Install script

Download the latest release [here](https://github.com/crowdsecurity/cs-nginx-blocker/releases)

```bash
tar xvzf cs-nginx-blocker.tgz
cd cs-nginx-blocker-v0.0.1
sudo ./install.sh
systemctl restart nginx
```

:warning: the installation script will take care of dependencies for Debian/Ubuntu
<details>
  <summary>non-debian based dependencies</summary>

  - libnginx-mod-http-lua : nginx lua support
  - lua-sql-sqlite3 : for SQLite support
  - lua-sql-mysql : for MySQL support
  - lua-logging : logging
</details>



## From source

### Requirements

The following packages are required :

- lua
- lua-sql-sqlite3
- lua-sql-mysql
- lua-logging
- libnginx-mod-http-lua

#### Debian/Ubuntu

```bash
sudo apt-get install lua5.3 libnginx-mod-http-lua lua-sql-sqlite3 lua-sql-mysql lua-logging
```

Download the following 2 repositories:

- [`cs-lua-lib`](https://github.com/crowdsecurity/cs-lua-lib):
```bash
git clone https://github.com/crowdsecurity/cs-lua-lib.git
```

- [`cs-nginx-blocker`](https://github.com/crowdsecurity/cs-nginx-blocker)
```bash
git clone https://github.com/crowdsecurity/cs-nginx-blocker.git
```

### Installation

#### cs-lua-lib

```bash
cd ./cs-lua-lib/
sudo make install
```

#### cs-nginx-blocker

- Copy the `cs-nginx-blocker/nginx/crowdsec_nginx.conf` into `/etc/nginx/conf.d/crowdsec_nginx.conf`:
```bash
cp ./cs-nginx-blocker/nginx/crowdsec_nginx.conf /etc/nginx/conf.d/crowdsec_nginx.conf
```
- Copy the `cs-nginx-blocker/nginx/access.lua` into `/usr/local/lua/crowdec/access.lua`:
```bash
cp ./cs-nginx-blocker/nginx/access.lua /usr/local/lua/crowdec/access.lua
```

You can now restart your nginx server:
```bash
systemctl restart nginx
```


# Configuration

The configuration file loaded by nginx is `/etc/nginx/conf.d/crowdsec_nginx.conf`, but you shouldn't have to edit it, the relevant configuration file being `/usr/local/lua/crowdsec/crowdsec.conf` :


```bash
# supported DATABASES : sqlite3, mysql
#DB_PATH is only for sqlite3
TYPE=sqlite3
DB_PATH=/var/lib/crowdsec/data/crowdsec.db
# Those parameters are only relevant for MySQL
#DB_NAME=
#DB_HOST=
#DB_PORT=
#DB_USERNAME=
#DB_PASSWORD=
# Where does the lua code put its logs
LOG_FILE=/tmp/lua_mod.log
# How many seconds is the information about an IP kept in cache
CACHE_EXPIRATION=1
# Cache size
CACHE_SIZE=1000
```



If instead of using SQLite you want to use MySQL, the configuration file will look like this :
```bash
# supported DATABASES : sqlite3, mysql
# DB_PATH is only for sqlite3
TYPE=mysql
DB_NAME=crowdsec
DB_HOST=localhost
# If you need a specific port
#DB_PORT=
DB_USERNAME=crowdsec
DB_PASSWORD=password
LOG_FILE=/tmp/lua_mod.log
CACHE_EXPIRATION=1
CACHE_SIZE=1000
```


# How it works

 - deploys `/etc/nginx/conf.d/crowdsec_nginx.conf` with `access_by_lua` directive
 - deploys `/usr/local/lua/crowdsec/access.lua` with the lua code checking incoming IPs against local db

# Testing

When your IP is blocked, any request should lead to a `403` http response.
