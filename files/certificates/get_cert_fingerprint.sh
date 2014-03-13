echo "Automation Server Encryption: "
openssl x509 -in /etc/puppet/atomiacerts/certificates/automationencrypt.crt -fingerprint -noout | sed 's/SHA1 Fingerprint='// | sed s/\://g

echo "Billing Encryption: "
openssl x509 -in /etc/puppet/atomiacerts/certificates/billingencrypt.crt -fingerprint -noout | sed 's/SHA1 Fingerprint='// | sed s/\://g

echo "Root cert: "
openssl x509 -in /etc/puppet/atomiacerts/ca.crt -fingerprint -noout | sed 's/SHA1 Fingerprint='// | sed s/\://g

echo "Signing: "
openssl x509 -in /etc/puppet/atomiacerts/certificates/stssigning.crt -fingerprint -noout | sed 's/SHA1 Fingerprint='// | sed s/\://g
