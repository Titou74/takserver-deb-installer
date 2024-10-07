# Tested on Ubuntu 22.04

## Install TAKSERVER

# Create required folder
sudo mkdir -p /etc/apt/keyrings

# Add postgresql repository
sudo curl https://www.postgresql.org/media/keys/ACCC4CF8.asc --output /etc/apt/keyrings/postgresql.asc
sudo sh -c 'echo "deb [signed-by=/etc/apt/keyrings/postgresql.asc] http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/postgresql.list'

# Update repository and upgrade system
sudo apt update
sudo apt upgrade

# If necessery
sudo reboot

# Upload the .deb file on the server on folder /tmp

# Install takserver from /tmp
cd /tmp
sudo apt install takserver_5.1-RELEASEx_all.deb

# Update daemon and start tak server
sudo systemctl daemon-reload
sudo systemctl start takserver

# Enable auto start on boot
sudo systemctl enable takserver

## Setup an SSL domain
# Setup an domain that point on your VPS

# Install certbot and generate SSL certificates for your domain
sudo apt install snap
sudo snap install --classic certbot
sudo certbot certonly --standalone

# SSL files is located on /etc/letsencrypt/live/<yourdomain.ext>/

# Generate certificates from Let's Encrypt files for TAK Server
mkdir /opt/tak/certs/letsencrypt
cd /opt/tak/certs/letsencrypt
mkdir renew/

# Respect syntax :
## yourdomain.ext --> with point separator --> google.fr
## yourdomain-ext --> with dash separator --> google-fr
#
# If password asked, use : atakatak
openssl pkcs12 -export -in /etc/letsencrypt/live/<yourdomain.ext>/fullchain.pem -inkey /etc/letsencrypt/live/<yourdomain.ext>/privkey.pem -out renew/<yourdomain-ext>.p12 -name <yourdomain.ext>
sudo keytool -importkeystore -destkeystore <yourdomain-ext>.jks -srckeystore renew/<yourdomain-ext>.p12 -srcstoretype pkcs12

## Configure user certificates
cd /opt/tak/certs

export STATE=state
export CITY=city
export ORGANIZATIONAL_UNIT=org_unit

# if asked if move file, answer YES
./makeRootCa.sh --ca-name takserver-CA
./makeCert.sh ca intermediate-CA
./makeCert.sh server takserver
./makeCert.sh client admin

service takserver restart
java -jar /opt/tak/utils/UserManager.jar usermod -A -p <admin-password> admin

## Update CoreConfig.xml file
cd /opt/tak
sudo nano CoreConfig.xml

# Inside the file, replace :
# <connector port="8446" clientAuth="false" _name="cert_https"/>
# with
# <connector port="8446" clientAuth="false" _name="cert_https" truststorePass="atakatak" truststoreFile="certs/files/truststore-intermediate-CA.jks" truststore="JKS" keystorePass="atakatak" keystoreFile="certs/letsencrypt/<yourdomain-ext>.jks" keystore="JKS"/>

# Remove if exist
# <input auth="anonymous" _name="stdtcp" protocol="tcp" port="8087"/>
# <input auth="anonymous" _name="stdudp" protocol="udp" port="8087"/>
# <input auth="anonymous" _name="streamtcp" protocol="stcp" port="8088"/>
# <connector port="8080" tls="false" _name="http_plaintext"/>

# Add before
# <input _name="stdssl" protocol="tls" port="8089" coreVersion="2"/>
# this line
# <input _name="cassl" auth="x509" protocol="tls" port="8089" />

# Add after
# <dissemination smartRetry="false"/>
# this lines
# <certificateSigning CA="TAKServer">
#        <certificateConfig>
#            <nameEntries>
#                <nameEntry name="O" value="TAK"/>
#                <nameEntry name="OU" value="TAK"/>
#            </nameEntries>
#        </certificateConfig>
#        <TAKServerCAConfig keystore="JKS" keystoreFile="/opt/tak/certs/files/intermediate-CA-signing.jks" keystorePass="atakatak" validityDays="30" signatureAlg="SHA256WithRSA"/>
#    </certificateSigning>

# Replace :
# <tls keystore="JKS" keystoreFile="certs/files/takserver.jks" keystorePass="atakatak" truststore="JKS" truststoreFile="certs/files/truststore-root.jks" truststorePass="atakatak" context="TLSv1.2" keymanager="SunX509"/>
# with
# <tls keystore="JKS" keystoreFile="certs/files/takserver.jks" keystorePass="atakatak" truststore="JKS" truststoreFile="certs/files/truststore-intermediate-CA.jks" truststorePass="atakatak" context="TLSv1.2" keymanager="SunX509"/>

# Replace
# <auth>
# with
# <auth x509groups="true" x509addAnonymous="false" x509useGroupCache="true" x509checkRevocation="true">

# Save file

# Restart server
sudo systemctl restart takserver

# Access to https://yourdomain.ext:8446/
