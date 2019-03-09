#!/usr/bin/bash

# Author: bm-zi


function break() {
echo '# '
sleep 4
clear
}

clear
sleep 1
echo '# userdel -r ldapuser01'
sleep 1
userdel -r ldapuser01
break

echo '# yum -y remove migrationtools'
sleep 1
yum -y remove migrationtools
break

echo '# yum -y install migrationtools'
sleep 1
yum -y install migrationtools
break

mkdir /home/guests
echo '# useradd -d /home/guests/ldapuser01 ldapuser01'
sleep 1
useradd -d /home/guests/ldapuser01 ldapuser01
echo '# ' ; clear

echo '# grep "ldapuser01" /etc/passwd > /root/users'
sleep 1
grep "ldapuser01" /etc/passwd > /root/users
break

echo '# grep "ldapuser01" /etc/group > /root/groups'
sleep 1
grep "ldapuser01" /etc/group > /root/groups
break

cat <<End-of-message

Do the following changes in file migrate_common.ph
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
\$DEFAULT_MAIL_DOMAIN = "home.local";
\$DEFAULT_BASE = "dc=home,dc=local";
\$EXTENDED_SCHEMA = 1;

End-of-message
printf "# " ; read x

echo '# vim /usr/share/migrationtools/migrate_common.ph'
sleep 1
vim /usr/share/migrationtools/migrate_common.ph
break

echo '# /usr/share/migrationtools/migrate_passwd.pl /root/users /root/users.ldif'
sleep 1
/usr/share/migrationtools/migrate_passwd.pl /root/users /root/users.ldif
break

echo '# /usr/share/migrationtools/migrate_group.pl /root/groups /root/groups.ldif'
sleep 1
/usr/share/migrationtools/migrate_group.pl /root/groups /root/groups.ldif
break

echo '# ldapadd -x -W -D "cn=ldapadm,dc=home,dc=local" -f /root/users.ldif'
sleep 1
ldapadd -x -W -D "cn=ldapadm,dc=home,dc=local" -f /root/users.ldif
break

echo '# ldapadd -x -W -D "cn=ldapadm,dc=home,dc=local" -f /root/groups.ldif'
sleep 1
ldapadd -x -W -D "cn=ldapadm,dc=home,dc=local" -f /root/groups.ldif
break

echo '# ldapsearch -x cn=ldapuser01 -b dc=home,dc=local'
sleep 1
ldapsearch -x cn=ldapuser01 -b dc=home,dc=local

echo '# systemctl restart slapd.service'
systemctl restart slapd.service




######
# TO DELETE ldapuser01 
# ldapdelete -x -W -D "cn=ldapadm,dc=home,dc=local" -r "cn=ldapuser01,ou=Group,dc=home,dc=local"


