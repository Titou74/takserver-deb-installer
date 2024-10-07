#!/bin/sh

# Default password is atakatak

rm -R renew/
mkdir renew

# Create our PKCS12 certificate from our signed certificate and private key
openssl pkcs12 -export -in /etc/letsencrypt/live/auratak.tf/fullchain.pem -inkey /etc/letsencrypt/live/auratak.tf/privkey.pem -out renew/auratak-tf.p12 -name auratak.tf

# View our PKCS12 content
# openssl pkcs12 -info -in renew/atakdil-fr.p12

# Create our Java Keystore from our PKCS12 certificate
sudo keytool -importkeystore -destkeystore renew/auratak-tf.jks -srckeystore renew/auratak-tf.p12 -srcstoretype pkcs12

# Move certificates
mv /opt/tak/certs/letsencrypt/* old-certificates/
mv renew/* /opt/tak/certs/letsencrypt/
chown -R tak:tak /opt/tak

# Configure user certificates
export STATE=state
export CITY=city
export ORGANIZATIONAL_UNIT=org_unit

# if asked if move file, answer YES
# mv /opt/tak/certs/files/ca.pem /opt/tak/certs/files/ca-old.pem
# keytool -delete -noprompt -alias "takserver-CA" -keystore "/opt/tak/certs/files/truststore-root.jks"
# cd /opt/tak/certs/
# ./makeRootCa.sh --ca-name takserver-CA
# ./makeCert.sh ca intermediate-CA
# ./makeCert.sh server takserver
# ./makeCert.sh client admin
