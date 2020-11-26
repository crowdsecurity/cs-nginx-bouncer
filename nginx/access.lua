-- Convert the Ip to integer, and check if present in sqlite
ok, err = require "CrowdSec".allowIp(ngx.var.remote_addr)
if err ~= nil then 
    ngx.log(ngx.ERR, "[Crowdsec] bouncer error " .. err)
end
if ok == nil then
   ngx.log(ngx.ERR, "[Crowdsec] " .. err)
end
if not ok then
    ngx.log(ngx.ERR, "[Crowdsec] denied '" .. ngx.var.remote_addr .. "'")
	ngx.exit(ngx.HTTP_FORBIDDEN)
end
