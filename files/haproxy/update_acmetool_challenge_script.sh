#!/bin/sh

thumbprint=`/usr/bin/acmetool account-thumbprint | awk '{ print $1 }'`
cat > /usr/lib/stateless_acme_challenge.lua <<EOF
global_account_thumbprint = "$thumbprint"

core.register_service("stateless_acme_challenge", "http", function(applet)
        local last_slash_index = string.find(applet.path, "/[^/]*\$")
        local response = string.sub(applet.path, last_slash_index + 1) .. "." .. global_account_thumbprint .. "\\n"

        applet:set_status(200)
        applet:add_header("content-length", string.len(response))
        applet:add_header("content-type", "text/plain")
        applet:start_response()
        applet:send(response)
end)
EOF
