#!/usr/bin/env ruby


if ARGV.size < 5
	p "Usage: <appdomain> <login> <order> <billing> <hcp>"
	p "Example: ruby generate_certificates.rb mydomain.com login order billing my"
	exit
end



appdomain = ARGV[0]
login = ARGV[1]
order = ARGV[2]
billing = ARGV[3]
hcp = ARGV[4]
actiontrail = "actiontrail"
admin = "admin"
automationserver = "automationserver"
sts = "sts"
userapi = "userapi"
billingapi = "billingapi"
accountapi = "accountapi"
orderapi = "orderapi"
wildcard = "*.#{appdomain}"
stssigning = "STS signing certificate"
automationencrypt = "Automation Server Data Encryption Cert"
billingencrypt = "Billing Data Encryption Certificate"
guicert = "Atomia GUI cert"
atomiadns = "atomiadns.#{appdomain}"

# Certificate info
ca_name="Atomia #{appdomain} Root Cert"

# Generate CA certificate
system("openssl genrsa -out private/ca.key 4096")
system("openssl req -new -x509 -days 7304 -subj \"/CN=#{ca_name}\" -key \"private/ca.key\" -out ca.crt -config ca.cnf")
system("openssl pkcs12 -export -in ca.crt -inkey private/ca.key  -name \"#{ca_name}\" -out certificates/root.pfx -passout pass:\"\" ")
#system("openssl req -new -x509 -days 7304 -subj \"/C=/ST=/L=/O=/CN=#{ca_name}\" -key \"private/ca.key\" -out ca.crt")
#system("openssl pkcs12 -export -in ca.crt -inkey private/ca.key  -name \"#{ca_name}\" -out certificates/root.pfx -passout pass:\"\" ")

# Generate keys
system("openssl genrsa -out \"private/actiontrail.key\" 4096")
system("openssl genrsa -out \"private/login.key\" 4096")
system("openssl genrsa -out \"private/order.key\" 4096")
system("openssl genrsa -out \"private/billing.key\" 4096")
system("openssl genrsa -out \"private/admin.key\" 4096")
system("openssl genrsa -out \"private/hcp.key\" 4096")
system("openssl genrsa -out \"private/automationserver.key\" 4096")
system("openssl genrsa -out \"private/sts.key\" 4096")
system("openssl genrsa -out \"private/userapi.key\" 4096")
system("openssl genrsa -out \"private/billingapi.key\" 4096")
system("openssl genrsa -out \"private/accountapi.key\" 4096")
system("openssl genrsa -out \"private/orderapi.key\" 4096")
system("openssl genrsa -out \"private/wildcard.key\" 4096")
system("openssl genrsa -out \"private/stssigning.key\" 4096")
system("openssl genrsa -out \"private/automationencrypt.key\" 4096")
system("openssl genrsa -out \"private/billingencrypt.key\" 4096")
system("openssl genrsa -out \"private/guicert.key\" 4096")
system("openssl genrsa -out \"private/atomiadns.key\" 4096")

# Generate CSRs
system("openssl req -new -key \"private/actiontrail.key\" -subj \"/C=/ST=/L=/O=/CN=#{actiontrail}.#{appdomain}\" -out \"csr/actiontrail.csr\"")
system("openssl req -new -key \"private/login.key\" -subj \"/C=/ST=/L=/O=/CN=#{login}.#{appdomain}\" -out \"csr/login.csr\"")
system("openssl req -new -key \"private/order.key\" -subj \"/C=/ST=/L=/O=/CN=#{order}.#{appdomain}\" -out \"csr/order.csr\"")
system("openssl req -new -key \"private/billing.key\" -subj \"/C=/ST=/L=/O=/CN=#{billing}.#{appdomain}\" -out \"csr/billing.csr\"")
system("openssl req -new -key \"private/admin.key\" -subj \"/C=/ST=/L=/O=/CN=#{admin}.#{appdomain}\" -out \"csr/admin.csr\"")
system("openssl req -new -key \"private/hcp.key\" -subj \"/C=/ST=/L=/O=/CN=#{hcp}.#{appdomain}\" -out \"csr/hcp.csr\"")
system("openssl req -new -key \"private/automationserver.key\" -subj \"/C=/ST=/L=/O=/CN=#{automationserver}.#{appdomain}\" -out \"csr/automationserver.csr\"")
system("openssl req -new -key \"private/sts.key\" -subj \"/C=/ST=/L=/O=/CN=#{sts}.#{appdomain}\" -out \"csr/sts.csr\"")
system("openssl req -new -key \"private/userapi.key\" -subj \"/C=/ST=/L=/O=/CN=#{userapi}.#{appdomain}\" -out \"csr/userapi.csr\"")
system("openssl req -new -key \"private/billingapi.key\" -subj \"/C=/ST=/L=/O=/CN=#{billingapi}.#{appdomain}\" -out \"csr/billingapi.csr\"")
system("openssl req -new -key \"private/accountapi.key\" -subj \"/C=/ST=/L=/O=/CN=#{accountapi}.#{appdomain}\" -out \"csr/accountapi.csr\"")
system("openssl req -new -key \"private/orderapi.key\" -subj \"/C=/ST=/L=/O=/CN=#{orderapi}.#{appdomain}\" -out \"csr/orderapi.csr\"")
system("openssl req -new -key \"private/wildcard.key\" -subj \"/C=/ST=/L=/O=/CN=*.#{appdomain}\" -out \"csr/wildcard.csr\"")
system("openssl req -new -key \"private/stssigning.key\" -subj \"/C=/ST=/L=/O=/CN=stssigning.#{appdomain}\" -out \"csr/stssigning.csr\"")
system("openssl req -new -key \"private/automationencrypt.key\" -subj \"/C=/ST=/L=/O=/CN=automationencrypt.#{appdomain}\" -out \"csr/automationencrypt.csr\"")
system("openssl req -new -key \"private/billingencrypt.key\" -subj \"/C=/ST=/L=/O=/CN=billingencrypt.#{appdomain}\" -out \"csr/billingencrypt.csr\"")
system("openssl req -new -key \"private/guicert.key\" -subj \"/C=/ST=/L=/O=/CN=guicert.#{appdomain}\" -out \"csr/guicert.csr\"")
system("openssl req -new -key \"private/atomiadns.key\" -subj \"/C=/ST=/L=/O=/CN=#{atomiadns}\" -out \"csr/atomiadns.csr\"")


def sign_certificate(file_name,certname)

    system("openssl x509 -req -days 3650 -in \"csr/#{file_name}.csr\" -CA ca.crt -CAkey \"private/ca.key\" -set_serial \"" + rand(100000000).to_s + "\" -extfile \"mycrl.cnf\" -extensions v3_custom -out \"certificates/#{file_name}.crt\"")
    system("openssl pkcs12 -export -in \"certificates/#{file_name}.crt\" -inkey \"private/#{file_name}.key\" -name \"#{certname}\" -out \"certificates/#{file_name}.pfx\" -passout pass:\"\" ")

end

# Sign certificates and export
sign_certificate("actiontrail",actiontrail)
sign_certificate("login",login)
sign_certificate("order",order)
sign_certificate("billing",billing)
sign_certificate("admin",admin)
sign_certificate("hcp",hcp)
sign_certificate("automationserver",automationserver)
sign_certificate("sts",sts)
sign_certificate("userapi",userapi)
sign_certificate("billingapi",billingapi)
sign_certificate("accountapi",accountapi)
sign_certificate("orderapi",orderapi)
sign_certificate("wildcard",wildcard)
sign_certificate("stssigning",stssigning)
sign_certificate("automationencrypt",automationencrypt)
sign_certificate("billingencrypt",billingencrypt)
sign_certificate("guicert",guicert)
sign_certificate("atomiadns",atomiadns)

system("openssl ca -config ca.cnf -gencrl -out empty.crl")
