#!/bin/sh

dir="/etc/puppet/hieradata"

cp "$dir"/windows.yaml "$dir"/windows.yaml.precertimport

thumb=`/etc/puppet/modules/atomia/files/certificates/get_cert_fingerprint.sh | grep -A 1 "Automation Server Encryption:" | tail -n 1`
sed -i -e 's,^\(atomia::windows_base::automationserver_encryption_cert_thumb: "\).*$,\1'"$thumb\"," "$dir"/windows.yaml

thumb=`/etc/puppet/modules/atomia/files/certificates/get_cert_fingerprint.sh | grep -A 1 "Billing Encryption:" | tail -n 1`
sed -i -e 's,^\(atomia::windows_base::billing_encryption_cert_thumb: "\).*$,\1'"$thumb\"," "$dir"/windows.yaml

thumb=`/etc/puppet/modules/atomia/files/certificates/get_cert_fingerprint.sh | grep -A 1 "Root cert:" | tail -n 1`
sed -i -e 's,^\(atomia::windows_base::root_cert_thumb: "\).*$,\1'"$thumb\"," "$dir"/windows.yaml

thumb=`/etc/puppet/modules/atomia/files/certificates/get_cert_fingerprint.sh | grep -A 1 "Signing:" | tail -n 1`
sed -i -e 's,^\(atomia::windows_base::signing_cert_thumb: "\).*$,\1'"$thumb\"," "$dir"/windows.yaml

echo "Imported certificate thumbprints according to following diff:"
diff -u "$dir"/windows.yaml.precertimport "$dir"/windows.yaml
rm -f "$dir"/windows.yaml.precertimport
