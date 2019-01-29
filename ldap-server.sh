#!/usr/bin/bash

function br(){
printf '# '
sleep 2
clear
}

function ejra (){
cmd=$1
echo "# $cmd"
sleep 1
eval $cmd
br
}

clear
echo ' ___________________________________ '
echo '|                                   |'
echo '| Install and configure ldap server |'
echo '|___________________________________|'
echo 
sleep 2
clear

ejra 'yum -y remove openldap-devel'
ejra 'yum -y remove openldap-servers-sql'
ejra 'yum -y remove openldap-servers'
ejra 'yum -y remove openldap-clients'
ejra 'yum -y remove compat-openldap'
ejra 'rm -rf /etc/openldap /var/lib/ldap'
ejra 'yum -y install openldap compat-openldap openldap-clients openldap-servers openldap-servers-sql openldap-devel'
ejra 'systemctl restart slapd.service'
ejra 'systemctl enable slapd.service'
ejra 'netstat -antup | grep -i 389'
ejra 'slappasswd -s redhat -n > /etc/openldap/slapd.d/passwd'

cat << EOF > /etc/openldap/slapd.d/db.ldif 
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=home,dc=local

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=ldapadm,dc=home,dc=local

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootPW
changehere
EOF

ejra 'cat /etc/openldap/slapd.d/db.ldif'
value=`cat /etc/openldap/slapd.d/passwd`
value="olcRootPW: $value"
sed -i "s|changehere|${value}|g" /etc/openldap/slapd.d/db.ldif
ejra 'cat /etc/openldap/slapd.d/db.ldif'
ejra 'ldapmodify -Y EXTERNAL  -H ldapi:/// -f /etc/openldap/slapd.d/db.ldif'

cat << EOF > /etc/openldap/slapd.d/monitor.ldif
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external, cn=auth" read by dn.base="cn=ldapadm,dc=home,dc=local" read by * none
EOF

ejra 'cat /etc/openldap/slapd.d/monitor.ldif'
ejra 'ldapmodify -Y EXTERNAL  -H ldapi:/// -f /etc/openldap/slapd.d/monitor.ldif'
ejra 'mkdir -p /etc/openldap/certs'
ejra 'openssl req -new -x509 -nodes -out /etc/openldap/certs/homeldap.cert -keyout /etc/openldap/certs/homeldap.key -days 365'
ejra 'chown -R ldap:ldap /etc/openldap/certs/home*'
ejra 'ls -l /etc/openldap/certs/home*'

cat << EOF > /etc/openldap/slapd.d/certs.ldif
dn: cn=config
changetype: modify
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/openldap/certs/homeldap.cert

dn: cn=config
changetype: modify
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/openldap/certs/homeldap.key
EOF

ejra 'cat /etc/openldap/slapd.d/certs.ldif'
ejra 'ldapmodify -Y EXTERNAL  -H ldapi:/// -f /etc/openldap/slapd.d/certs.ldif'
ejra 'slaptest -u'
ejra 'rm -f /var/lib/ldap/DB_CONFIG'
ejra 'cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG'
ejra 'chown ldap:ldap /var/lib/ldap/*'
ejra 'ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif'
ejra 'ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif'
ejra 'ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif'

cat << EOF > /etc/openldap/slapd.d/base.ldif
dn: dc=home,dc=local
dc: home
objectClass: top
objectClass: domain

dn: cn=ldapadm,dc=home,dc=local
objectClass: organizationalRole
cn: ldapadm
description: LDAP Manager

dn: ou=People,dc=home,dc=local
objectClass: organizationalUnit
ou: People

dn: ou=Group,dc=home,dc=local
objectClass: organizationalUnit
ou: Group
EOF

ejra 'cat /etc/openldap/slapd.d/base.ldif'
ejra 'ldapadd -x -W -D "cn=ldapadm,dc=home,dc=local" -f /etc/openldap/slapd.d/base.ldif'

echo
echo "ldap server set up completed!"
echo

# Country Name (2 letter code) [XX]:XX
# State or Province Name (full name) []:XX 
# Locality Name (eg, city) [Default City]:XXXXXX
# Organization Name (eg, company) [Default Company Ltd]:home
# Organizational Unit Name (eg, section) []:IT Infra
# Common Name (eg, your name or your server's hostname) []:ldapsrv.home.local
# Email Address []: admin@home.local

# ldapadd -x -W -D "cn=ldapadm,dc=home,dc=local" -f users.ldif 
# ldappasswd -s password -W -D "cn=ldapadm,dc=home,dc=local" -x "uid=ldapuser01,ou=People,dc=home,dc=local"
# ldappasswd -s password -W -D "cn=ldapadm,dc=home,dc=local" -x "uid=ldapuser02,ou=People,dc=home,dc=local"
# ldapsearch -x cn=ldapuser01 -b dc=home,dc=local


# #############################
# SCRIPT TO CREATE AN LDAP USER
# #############################

clear
echo ' _____________________________________'
echo '|                                     |'
echo '| Adding a ldap user to ldap database |'
echo '|_____________________________________|'
echo 
sleep 2
clear

ejra 'userdel -r ldapuser01'
ejra 'yum -y remove migrationtools'
ejra 'yum -y install migrationtools'
ejra 'mkdir -p /home/ldap'
ejra 'useradd -d /home/ldap/ldapuser01 ldapuser01'
ejra 'grep "ldapuser01" /etc/passwd > /root/users'
ejra 'grep "ldapuser01" /etc/group > /root/groups'

cat <<End-of-message

Do the following changes in file migrate_common.ph
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
\$DEFAULT_MAIL_DOMAIN = "home.local";
\$DEFAULT_BASE = "dc=home,dc=local";
\$EXTENDED_SCHEMA = 1;

End-of-message
printf "Continue?[Enter] " ; read x

ejra 'vim /usr/share/migrationtools/migrate_common.ph'
ejra '/usr/share/migrationtools/migrate_passwd.pl /root/users /root/users.ldif'
ejra '/usr/share/migrationtools/migrate_group.pl /root/groups /root/groups.ldif'
ejra 'ldapadd -x -W -D "cn=ldapadm,dc=home,dc=local" -f /root/users.ldif'
ejra 'ldapadd -x -W -D "cn=ldapadm,dc=home,dc=local" -f /root/groups.ldif'
ejra 'ldapsearch -x cn=ldapuser01 -b dc=home,dc=local'
ejra 'systemctl restart slapd.service'

echo
echo "ldap user ldapuser01 has been added to ldap database!"
echo

######
# TO DELETE ldapuser01 
# ldapdelete -x -W -D "cn=ldapadm,dc=home,dc=local" -r "cn=ldapuser01,ou=Group,dc=home,dc=local"
