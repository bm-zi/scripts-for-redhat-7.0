#!/usr/bin/bash

#########################################################
# Script for configuring openldap on redhat/CentOS server
######################################################### 
#
# This script tested on a rhel/CentOS server version 7.0
# This script installs and configures an ldap server
# The local domain name used in script is 'hdc.mylab.com'
# Change the domain name in script to the name of your own domain.
# You have to have access to a local/remote yum repository for installing necessary packages
# The admin for modifying ldap entries is 'ldapadm' 
# The password for modifying ldap entries is 'redhat'
# 
#
# To answer the questions while running openssl command,
# you can answer like following example:
#
# Country Name (2 letter code) [XX]:XX
# State or Province Name (full name) []:XX 
# Locality Name (eg, city) [Default City]:XXXXXX
# Organization Name (eg, company) [Default Company Ltd]:mylab
# Organizational Unit Name (eg, section) []:IT
# Common Name (eg, your name or your server's hostname) []:ldapsrv.hdc.mylab.com
# Email Address []: admin@hdc.mylab.com
#
##################
# Date: 2017-12-10 


clear
echo '# yum -y remove openldap-devel'
sleep 4
yum -y remove openldap-devel
echo '# yum -y openldap-servers-sql'
sleep 4
yum -y remove openldap-servers-sql
echo '# yum -y openldap-servers'
sleep 4
yum -y remove openldap-servers
echo '# yum -y openldap-clients'
sleep 4
yum -y remove openldap-clients
echo '# yum -y compat-openldap'
sleep 4
yum -y remove compat-openldap

sleep 4
clear
echo 'yum -y install openldap compat-openldap openldap-clients openldap-servers openldap-servers-sql openldap-devel'
sleep 4
# for i in `seq 1 6`;do echo;done
yum -y install openldap compat-openldap openldap-clients openldap-servers openldap-servers-sql openldap-devel

sleep 4
clear
echo '# systemctl restart slapd.service'
systemctl restart slapd.service

sleep 4
clear
echo '# systemctl enable slapd.service'
systemctl enable slapd.service

sleep 4
clear
echo '# netstat -antup | grep -i 389'
netstat -antup | grep -i 389

sleep 4
clear
echo '# slappasswd -s redhat -n > /etc/openldap/slapd.d/passwd'
slappasswd -s redhat -n > /etc/openldap/slapd.d/passwd

sleep 4
clear
echo '# cat /etc/openldap/slapd.d/db.ldif'
cat << EOF > /etc/openldap/slapd.d/db.ldif 
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=hdc.mylab,dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=ldapadm,dc=hdc.mylab,dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootPW
changehere
EOF

cat /etc/openldap/slapd.d/db.ldif

value=`cat /etc/openldap/slapd.d/passwd`
value="olcRootPW: $value"

sleep 4
clear
echo '# sed -i "s|changehere|${value}|g" /etc/openldap/slapd.d/db.ldif'
sed -i "s|changehere|${value}|g" /etc/openldap/slapd.d/db.ldif

sleep 4
clear
echo '# cat /etc/openldap/slapd.d/db.ldif'
cat /etc/openldap/slapd.d/db.ldif

sleep 4
clear
echo '# ldapmodify -Y EXTERNAL  -H ldapi:/// -f /etc/openldap/slapd.d/db.ldif'
ldapmodify -Y EXTERNAL  -H ldapi:/// -f /etc/openldap/slapd.d/db.ldif


sleep 4
clear
echo '# cat /etc/openldap/slapd.d/monitor.ldif'
cat << EOF > /etc/openldap/slapd.d/monitor.ldif
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external, cn=auth" read by dn.base="cn=ldapadm,dc=hdc.mylab,dc=com" read by * none
EOF

cat /etc/openldap/slapd.d/monitor.ldif

sleep 4
clear
echo '# ldapmodify -Y EXTERNAL  -H ldapi:/// -f /etc/openldap/slapd.d/monitor.ldif' 
ldapmodify -Y EXTERNAL  -H ldapi:/// -f /etc/openldap/slapd.d/monitor.ldif 

sleep 4
clear
echo '# openssl req -new -x509 -nodes -out /etc/openldap/certs/mylabcert.pem -keyout /etc/openldap/certs/mylabldapkey.pem -days 365'
sleep 4
openssl req -new -x509 -nodes -out /etc/openldap/certs/mylabcert.pem -keyout /etc/openldap/certs/mylabldapkey.pem -days 365

sleep 4
clear
echo '# chown -R ldap:ldap /etc/openldap/certs/*.pem'
chown -R ldap:ldap /etc/openldap/certs/*.pem

sleep 4
clear
echo '# cat /etc/openldap/slapd.d/certs.ldif'
cat << EOF > /etc/openldap/slapd.d/certs.ldif
dn: cn=config
changetype: modify
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/openldap/certs/mylabldapcert.pem

dn: cn=config
changetype: modify
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/openldap/certs/mylabldapkey.pem
EOF

cat /etc/openldap/slapd.d/certs.ldif

sleep 4
clear
echo '# ldapmodify -Y EXTERNAL  -H ldapi:/// -f /etc/openldap/slapd.d/certs.ldif'
ldapmodify -Y EXTERNAL  -H ldapi:/// -f /etc/openldap/slapd.d/certs.ldif

sleep 4
clear
echo '# slaptest -u'
slaptest -u

sleep 4
clear
echo '# rm -f /var/lib/ldap/DB_CONFIG'
rm -f /var/lib/ldap/DB_CONFIG

sleep 4
clear
echo '# cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG'
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
sleep 4
clear
echo '# chown ldap:ldap /var/lib/ldap/*'
chown ldap:ldap /var/lib/ldap/*
sleep 4
clear
echo '# ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif'
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
sleep 4
clear
echo '# ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif'
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
sleep 4
clear
echo '# ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif'
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

sleep 4
clear
echo '# cat /etc/openldap/slapd.d/base.ldif'
cat << EOF > /etc/openldap/slapd.d/base.ldif
dn: dc=hdc.mylab,dc=com
dc: hdc.mylab
objectClass: top
objectClass: domain

dn: cn=ldapadm ,dc=hdc.mylab,dc=com
objectClass: organizationalRole
cn: ldapadm
description: LDAP Manager

dn: ou=People,dc=hdc.mylab,dc=com
objectClass: organizationalUnit
ou: People

dn: ou=Group,dc=hdc.mylab,dc=com
objectClass: organizationalUnit
ou: Group
EOF

cat /etc/openldap/slapd.d/base.ldif

sleep 4
clear
echo  '# ldapadd -x -W -D "cn=ldapadm,dc=hdc.mylab,dc=com" -f /etc/openldap/slapd.d/base.ldif '
ldapadd -x -W -D "cn=ldapadm,dc=hdc.mylab,dc=com" -f /etc/openldap/slapd.d/base.ldif

