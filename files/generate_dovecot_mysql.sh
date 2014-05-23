#!/bin/sh

cat <<EOF
driver = mysql
connect = host=$1 dbname=$2 user=$3 password=$4
default_pass_scheme = CRYPT
user_query = SELECT CONCAT('maildir:/storage/virtual/', maildir) AS mail, '2000' AS uid, '2000' AS gid, CONCAT('maildir:storage=', floor(quota*1024)) AS quota FROM user WHERE email = (SELECT IF((SELECT email from user where email = '%u') is not null, '%u', CONCAT('@','%d')))
password_query = SELECT email AS user, NULL as password, 'Y' as nopassword FROM user WHERE email = '%u' AND (ENCRYPT('%w', LEFT(password, 2)) = password OR MD5('%w') = password)
EOF

