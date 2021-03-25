-- Convert the Ip to integer, and check if present in sqlite
remoteAddr = ngx.var.remote_addr;
if ngx.var.http_x_forwarded_for then
    remoteAddr = string.match(ngx.var.http_x_forwarded_for, "^([^,]*)")
end

ok, err = require "CrowdSec".allowIp(remoteAddr)
if err ~= nil then
    ngx.log(ngx.ERR, "[Crowdsec] bouncer error " .. err)
end
if ok == nil then
   ngx.log(ngx.ERR, "[Crowdsec] " .. err)
end
if not ok then
    ngx.log(ngx.ERR, "[Crowdsec] denied '" .. remoteAddr .. "'")
	ngx.exit(ngx.HTTP_FORBIDDEN)
end
