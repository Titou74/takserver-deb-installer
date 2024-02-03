#!/bin/sh

# Default password is atakatak

domain=atakdil.fr
fileName=atakdil-fr

rm -R renew/
mkdir renew

# Create our PKCS12 certificate from our signed certificate and private key
openssl pkcs12 -export -in /etc/letsencrypt/live/atakdil.fr/fullchain.pem -inkey /etc/letsencrypt/live/atakdil.fr/privkey.pem -out renew/atakdil-fr.p12 -name atakdil.fr

# View our PKCS12 content
# openssl pkcs12 -info -in renew/atakdil-fr.p12

# Create our Java Keystore from our PKCS12 certificate
sudo keytool -importkeystore -destkeystore renew/atakdil-fr.jks -srckeystore renew/atakdil-fr.p12 -srcstoretype pkcs12

# Move certificates
mv /opt/tak/certs/letsencrypt/* old-certificates/
mv renew/* /opt/tak/certs/letsencrypt/