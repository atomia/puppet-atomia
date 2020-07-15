#!/bin/sh

# This is a new implementation of the update acmetool challange script.
# We no longer use the actual acme-tool, as it is not good for may domains.
# We switched to certbot, but it does not support getting challange directly so we need to calculate it.

# We first need to chec if there is already an account, and if not then we create a new one.
if [ ! -f "/etc/letsencrypt/accounts/acme-v01.api.letsencrypt.org/directory/*/private_key.json" ]
then
	logger "Could not find Let's encrypt account info, creating new account with certbot..."
	certbot register --agree-tos -m noreply@atomia.com
fi

# Certbot saves the private_key info in the .json file, so we need a few values from the whole json file, not the whole file.
# We parse the n and e keys from the file which are used in calculation of the jwk (account thumbprint).
n="`cat /etc/letsencrypt/accounts/acme-v01.api.letsencrypt.org/directory/*/private_key.json | python -c "import sys, json; print json.load(sys.stdin)['n']"`"
e="`cat /etc/letsencrypt/accounts/acme-v01.api.letsencrypt.org/directory/*/private_key.json | python -c "import sys, json; print json.load(sys.stdin)['e']"`"

jwk='{"e": "'$e'", "kty": "RSA", "n": "'$n'"}'

# These are the functions that are pulled from.
# https://github.com/Neilpang/acme.sh/blob/master/acme.sh
# That's a Bash implementation of acme utility for Lets encrypt.
_url_replace() {
  tr '/+' '_-' | tr -d '= '
}

#Usage: multiline
_base64() {
  [ "" ] #urgly
  if [ "$1" ]; then
    logger "base64 multiline:'$1'"
    ${ACME_OPENSSL_BIN:-openssl} base64 -e
  else
    logger "base64 single line."
    ${ACME_OPENSSL_BIN:-openssl} base64 -e | tr -d '\r\n'
  fi
}

#Usage: hashalg  [outputhex]
#Output Base64-encoded digest
_digest() {
  alg="$1"
  if [ -z "$alg" ]; then
    echo "Usage: _digest hashalg"
    return 1
  fi

  outputhex="$2"

  if [ "$alg" = "sha256" ] || [ "$alg" = "sha1" ] || [ "$alg" = "md5" ]; then
    if [ "$outputhex" ]; then
      ${ACME_OPENSSL_BIN:-openssl} dgst -"$alg" -hex | cut -d = -f 2 | tr -d ' '
    else
      ${ACME_OPENSSL_BIN:-openssl} dgst -"$alg" -binary | _base64
    fi
  else
    logger "$alg is not supported yet"
    return 1
  fi

}

__calc_account_thumbprint() {
  printf "%s" "$jwk" | tr -d ' ' | _digest "sha256" | _url_replace
}

# Now we are ready to calculate the thumbprint so we can call the function.
# The thumbprint var will now contain the calculated thumbprint in the format that Let's encrypt needs for verification.
thumbprint=$(__calc_account_thumbprint)

# Finally we create the lua file that is loaded by haproxy in order for the challange to pass.
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
