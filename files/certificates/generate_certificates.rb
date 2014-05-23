#!/usr/bin/env ruby
require 'fileutils'

if ARGV.size < 5
        p "Usage: <appdomain> <login> <order> <billing> <hcp>"
        p "Example: ruby generate_certificates.rb mydomain.com login order billing my"
        exit
end


certpath = "/etc/puppet/atomiacerts/"
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

unless File.directory?(certpath)
  FileUtils.mkdir_p(certpath)
end

unless File.directory?("#{certpath}/certificates")
  FileUtils.mkdir_p("#{certpath}/certificates")
end

unless File.directory?("#{certpath}/private")
  FileUtils.mkdir_p("#{certpath}/private")
end

unless File.directory?("#{certpath}/csr")
  FileUtils.mkdir_p("#{certpath}/csr")
end

# Certificate info
ca_name="Atomia #{appdomain} Root Cert"

# Generate CA certificate
system("openssl genrsa -out #{certpath}private/ca.key 4096")
system("openssl req -new -x509 -days 7304 -subj \"/CN=#{ca_name}\" -key \"#{certpath}private/ca.key\" -out #{certpath}ca.crt -config ca.cnf")
system("openssl pkcs12 -export -in #{certpath}ca.crt -inkey #{certpath}private/ca.key  -name \"#{ca_name}\" -out #{certpath}certificates/root.pfx -passout pass:\"\" ")
#system("openssl req -new -x509 -days 7304 -subj \"/C=/ST=/L=/O=/CN=#{ca_name}\" -key \"#{certpath}private/ca.key\" -out ca.crt")
#system("openssl pkcs12 -export -in ca.crt -inkey #{certpath}private/ca.key  -name \"#{ca_name}\" -out #{certpath}certificates/root.pfx -passout pass:\"\" ")

# Generate keys
system("openssl genrsa -out \"#{certpath}private/actiontrail.key\" 4096")
system("openssl genrsa -out \"#{certpath}private/login.key\" 4096")
system("openssl genrsa -out \"#{certpath}private/order.key\" 4096")
system("openssl genrsa -out \"#{certpath}private/billing.key\" 4096")
system("openssl genrsa -out \"#{certpath}private/admin.key\" 4096")
system("openssl genrsa -out \"#{certpath}private/hcp.key\" 4096")
system("openssl genrsa -out \"#{certpath}private/automationserver.key\" 4096")
system("openssl genrsa -out \"#{certpath}private/sts.key\" 4096")
system("openssl genrsa -out \"#{certpath}private/userapi.key\" 4096")
system("openssl genrsa -out \"#{certpath}private/billingapi.key\" 4096")
system("openssl genrsa -out \"#{certpath}private/accountapi.key\" 4096")
system("openssl genrsa -out \"#{certpath}private/orderapi.key\" 4096")
system("openssl genrsa -out \"#{certpath}private/wildcard.key\" 4096")
system("openssl genrsa -out \"#{certpath}private/stssigning.key\" 4096")
system("openssl genrsa -out \"#{certpath}private/automationencrypt.key\" 4096")
system("openssl genrsa -out \"#{certpath}private/billingencrypt.key\" 4096")
system("openssl genrsa -out \"#{certpath}private/guicert.key\" 4096")
system("openssl genrsa -out \"#{certpath}private/atomiadns.key\" 4096")

# Generate CSRs
system("openssl req -new -key \"#{certpath}private/actiontrail.key\" -subj \"/C=/ST=/L=/O=/CN=#{actiontrail}.#{appdomain}\" -out \"#{certpath}csr/actiontrail.csr\"")
system("openssl req -new -key \"#{certpath}private/login.key\" -subj \"/C=/ST=/L=/O=/CN=#{login}.#{appdomain}\" -out \"#{certpath}csr/login.csr\"")
system("openssl req -new -key \"#{certpath}private/order.key\" -subj \"/C=/ST=/L=/O=/CN=#{order}.#{appdomain}\" -out \"#{certpath}csr/order.csr\"")
system("openssl req -new -key \"#{certpath}private/billing.key\" -subj \"/C=/ST=/L=/O=/CN=#{billing}.#{appdomain}\" -out \"#{certpath}csr/billing.csr\"")
system("openssl req -new -key \"#{certpath}private/admin.key\" -subj \"/C=/ST=/L=/O=/CN=#{admin}.#{appdomain}\" -out \"#{certpath}csr/admin.csr\"")
system("openssl req -new -key \"#{certpath}private/hcp.key\" -subj \"/C=/ST=/L=/O=/CN=#{hcp}.#{appdomain}\" -out \"#{certpath}csr/hcp.csr\"")
system("openssl req -new -key \"#{certpath}private/automationserver.key\" -subj \"/C=/ST=/L=/O=/CN=#{automationserver}.#{appdomain}\" -out \"#{certpath}csr/automationserver.csr\"")
system("openssl req -new -key \"#{certpath}private/sts.key\" -subj \"/C=/ST=/L=/O=/CN=#{sts}.#{appdomain}\" -out \"#{certpath}csr/sts.csr\"")
system("openssl req -new -key \"#{certpath}private/userapi.key\" -subj \"/C=/ST=/L=/O=/CN=#{userapi}.#{appdomain}\" -out \"#{certpath}csr/userapi.csr\"")
system("openssl req -new -key \"#{certpath}private/billingapi.key\" -subj \"/C=/ST=/L=/O=/CN=#{billingapi}.#{appdomain}\" -out \"#{certpath}csr/billingapi.csr\"")
system("openssl req -new -key \"#{certpath}private/accountapi.key\" -subj \"/C=/ST=/L=/O=/CN=#{accountapi}.#{appdomain}\" -out \"#{certpath}csr/accountapi.csr\"")
system("openssl req -new -key \"#{certpath}private/orderapi.key\" -subj \"/C=/ST=/L=/O=/CN=#{orderapi}.#{appdomain}\" -out \"#{certpath}csr/orderapi.csr\"")
system("openssl req -new -key \"#{certpath}private/wildcard.key\" -subj \"/C=/ST=/L=/O=/CN=*.#{appdomain}\" -out \"#{certpath}csr/wildcard.csr\"")
system("openssl req -new -key \"#{certpath}private/stssigning.key\" -subj \"/C=/ST=/L=/O=/CN=stssigning.#{appdomain}\" -out \"#{certpath}csr/stssigning.csr\"")
system("openssl req -new -key \"#{certpath}private/automationencrypt.key\" -subj \"/C=/ST=/L=/O=/CN=automationencrypt.#{appdomain}\" -out \"#{certpath}csr/automationencrypt.csr\"")
system("openssl req -new -key \"#{certpath}private/billingencrypt.key\" -subj \"/C=/ST=/L=/O=/CN=billingencrypt.#{appdomain}\" -out \"#{certpath}csr/billingencrypt.csr\"")
system("openssl req -new -key \"#{certpath}private/guicert.key\" -subj \"/C=/ST=/L=/O=/CN=guicert.#{appdomain}\" -out \"#{certpath}csr/guicert.csr\"")
system("openssl req -new -key \"#{certpath}private/atomiadns.key\" -subj \"/C=/ST=/L=/O=/CN=#{atomiadns}\" -out \"#{certpath}csr/atomiadns.csr\"")


def sign_certificate(file_name,certname,cert_path)

    system("openssl x509 -req -days 3650 -in \"#{cert_path}csr/#{file_name}.csr\" -CA #{cert_path}ca.crt -CAkey \"#{cert_path}private/ca.key\" -set_serial \"" + rand(100000000).to_s + "\" -extfile \"mycrl.cnf\" -extensions v3_custom -out \"#{cert_path}certificates/#{file_name}.crt\"")
    system("openssl pkcs12 -export -in \"#{cert_path}certificates/#{file_name}.crt\" -inkey \"#{cert_path}private/#{file_name}.key\" -name \"#{certname}\" -out \"#{cert_path}certificates/#{file_name}.pfx\" -passout pass:\"\" ")

end

# Sign certificates and export
sign_certificate("actiontrail",actiontrail,certpath)
sign_certificate("login",login,certpath)
sign_certificate("order",order,certpath)
sign_certificate("billing",billing,certpath)
sign_certificate("admin",admin,certpath)
sign_certificate("hcp",hcp,certpath)
sign_certificate("automationserver",automationserver,certpath)
sign_certificate("sts",sts,certpath)
sign_certificate("userapi",userapi,certpath)
sign_certificate("billingapi",billingapi,certpath)
sign_certificate("accountapi",accountapi,certpath)
sign_certificate("orderapi",orderapi,certpath)
sign_certificate("wildcard",wildcard,certpath)
sign_certificate("stssigning",stssigning,certpath)
sign_certificate("automationencrypt",automationencrypt,certpath)
sign_certificate("billingencrypt",billingencrypt,certpath)
sign_certificate("guicert",guicert,certpath)
sign_certificate("atomiadns",atomiadns,certpath)

system("openssl ca -config ca.cnf -gencrl -out #{certpath}empty.crl")