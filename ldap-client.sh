#!/usr/bin/bash

# Author: bm-zi

# ABOUT THIS SCRIPT:
# THIS SCRIPT CONFIGURES NFS SHARE ON REDHAT/CENTOS 7.0.
# THE OPERATION WILL BE DONE STEP BY STEP, INTERACTING WITH YOU.
# WHEN YOU SEE THE PROMPT "# " THEN YOU CAN PRESS ENTER TO
# CONTINUE THE OPERATIONS.


# VARIABLES DEFINITION
b=$(tput smso)
n=$(tput rmso)

# FUNCTIONS START

# FUNCTION TO ECHO THE COMMAND AND ASK FOR EXECUTING THE COMMAND
# ##############################################################
function runit () {
com=$1
echo ' COMMAND TO BE RUN:'
#echo "$com" | sed 's/./~/g'
echo " ${b}$com${n}"
#echo "$com" | sed 's/./~/g'
echo " [q]exit | [s]skip | [Enter]run?"
echo
printf "# " ; read confirmation 

if [[ $confirmation =~ 'q' ]]; 
   then exit 0;  
elif [[ $confirmation =~ 's' ]];
   then printf "# "
else 
   clear
   echo "# $com" 
   sleep 1
   /bin/bash -c "$com"
   printf "# " ; read x
fi
}

# FUNCTIONS END



# STARTING MAIN BODY
clear
echo "${b}ldap-client configuration on RHEL 7 or CentOS 7${n}"

cat <<EOF

 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Operations to be done in Summary:
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Remove openldap basic package and openldap-client package,
 if they exist and configured previously.

 Remove ldap-clients package and then later do a fresh install 
 of these packages.

 Configure system authentication resources with authconfig.

 Restarting the openldap client service, and checking the 
 service status.

 Check if can reach to ldap database and search for an existing ldap user.
 Configure autofs for nfs share from ldap server.


EOF

clear
printf 'Enter the name of ldap server: ' ; read ldapserver
printf 'Enter the name of domain controllers[like: dc=home,dc=local] ' ; read domainctl
printf 'Enter the name of an existing ldap  user: ' ; read ldapuser
sleep 1
clear

cat <<EOF
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Confirm highlighted information:
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 ldap server name: ${b}$ldapserver${n} 

 domain name: ${b}$domainctl${n}

 existing ldap user: ${b}$ldapuser${n}

EOF

printf ' Confirm?[y|n] ' ; read ans;
if [[ $ans =~ [nN] ]]; then exit 0; fi

clear; cat <<EOF
 Prepare system for new ldap client configuration:
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Remove all ldap configurations and reinstall the basic ldap package.
 Remove all other packages required for ldap client and do a fresh 
 install.


EOF

runit 'rm -rf /etc/openldap && yum reinstall openldap -y' ; clear
runit 'yum remove openldap-clients nss-pam-ldapd -y' ; clear
runit 'yum install openldap-clients nss-pam-ldapd -y'

clear ; cat <<EOF 
 Prevent LDAP client using SSSD authentication:
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Use authconfig command to disable SSSD authentication, to avoid using SSSD implicitly, 
 run command authconfig with option --enableforcelegacy

 After running above command, the empty directory /etc/openldap/cacerts will be created!
 In man page for authconfig there is no information for option '--enableforcelegacy'.
 (You will find this option when running 'authconfig --help')

  # authconfig --help | grep legacy
    --enableforcelegacy     never use SSSD implicitly even for supported configurations
    --disableforcelegacy    use SSSD implicitly if it supports the configuration


EOF

runit 'authconfig --enableforcelegacy --update'

clear; cat <<EOF
 Let Client Communicate LDAP Server:
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Run 'authconfig -h | grep ldap' to know about this option.

 Options that you need to know for command authconfig:
  --enableldap  enables LDAP for user information by default
  --enableldapauth enables LDAP for authentication by default
  --ldapserver=ldap_server_name defines default LDAP server hostname or URI
  --ldapbasedn= determins the default LDAP base DN
  --enablemkhomedir create home directories for users on their first login


EOF

ldap_server="ldap://$ldapserver"
runit "authconfig --enableldap --enableldapauth --ldapserver="$ldap_server" --ldapbasedn="$domainctl" --enablemkhomedir --update"


clear ; cat <<EOF
 Using TLS
 ~~~~~~~~~
 Transport Layer Security (TLS), and its now-deprecated predecessor, 
 Secure Sockets Layer (SSL),are cryptographic protocols designed to 
 provide communications security over a computer network.

 Several versions of the protocols find widespread use in applications 
 such as web browsing, email, instant messaging, and voice over IP (VoIP). 
 Websites can use TLS to secure all communications between their servers and web browsers. 

 We use TLS for a secure communication between client and ldap server.
 (We get TLS certificate from LDAP server.) 

EOF
runit "authconfig --enableldaptls --ldaploadcacert="http://$ldapserver/pub/homeldap.cert" --update"

clear ; cat <<EOF
 TLS Certificate Verification:
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 When TLS enabled, We also let ldap client service (nslcd) to allow 
 certificate verification, by adding the following entry to the end 
 of file /etc/nslcd.conf:

 tls_reqcert allow


EOF

runit "echo 'tls_reqcert allow' >> /etc/nslcd.conf"
runit "tail /etc/nslcd.conf"

clear ; cat <<EOF
 Restarting Service
 ~~~~~~~~~~~~~~~~~~
 Now configuration has been completed. After reloading openldap client service, 
 we will check the service status to see if there is any issue.

EOF
runit 'systemctl enable nslcd.service && systemctl restart nslcd.service && systemctl status nslcd.service'


clear ; cat <<EOF
 Check LDAP Server Availability:
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Now we are going to check if can reach to ldap database,
 and search for an existing ldap user.($ldapusre)
 

EOF
runit "getent passwd $ldapuser"

clear ; cat <<EOF
 About ldapsearch command
 ~~~~~~~~~~~~~~~~~~~~~~~~
 ldapsearch options to know:
   -x  Use simple authentication instead of SASL.
   -b  searchbase - Use searchbase as the starting point for the search instead of the default.


EOF
runit "ldapsearch -x cn=$ldapuser -b dc=home,dc=local"

clear ; cat <<EOF
 About autofs and nfs share:
 ~~~~~~~~~~~~~~~~~~~~~~~~~~
 We can check if autofs is installed and also the showmount command is available:
 # yum provides showmount && rpm -q autofs

 Install a fresh copy of autofs and nfs-utils, and check if autofs service started.

 Check if ldapserver is sharing any file and it is dynamically mounted by autofs, 
 under /net, by running 'ls /net/ldapserver_name/'

 We also can check autofs for ldapserver by appending a line to /etc/auto.misc like below:
 data	-ro	ldapsrv:/rhome
 Then after restarting autofs service you will see for example the below output:
 # ls /misc/data
 data.txt
  
EOF

runit 'yum remove autofs nfs-utils -y && yum install autofs nfs-utils -y'
runit 'systemctl start autofs && systemctl enable autofs && systemctl status autofs'
runit "showmount -e $ldapserver"
#cmd4=$(for i in `showmount -e ldapsrv | grep "^/" | awk '{print $1}'`; do ls /net/ldapsrv$i; done)
runit "ls /net/$ldapserver/ && df -Th | grep nfs"


clear ; cat <<EOF
 autofs configuration
 ~~~~~~~~~~~~~~~~~~~~
 autofs dynamically mounts the nfs share under /net/ldapserver_name or under /misc/name_of_dir,
 if  /etc/auto.misc is modified, but still when login as an ldap user in an ldap client server,
 it complains as below:
 "su: warning: cannot change directory to ... : No such file or directory"
 The mount will take places once that particular directory is accessed!

 The solution to above is to make an static autofs configuration as following:
 Create a new directory and specify that as a place holder for autofs in /etc/auto.master file,
 or a new config file in /etc/auto.master.d directory

EOF
runit 'mkdir -p /home/ldap'
cat<<EOF > /etc/auto.master.d/home.autofs
/home/ldap  /etc/auto.home
EOF
runit 'cat /etc/auto.master.d/home.autofs'

clear ; cat <<EOF
 autofs map file:
 ~~~~~~~~~~~~~~~~
 As to previous operation a config file is already created in directory /etc/auto.master.d/ 
 that shows the directory location for automount. 
 This config file also shows the place of autofs map file.

 Create that autofs map file and restart the autofs service.
 (We always can get help from content of /etc/auto.misc to create a map file.)

EOF
cat <<EOF > /etc/auto.home
*   $ldapserver://home/ldap/&
EOF
runit 'cat /etc/auto.home'
runit 'systemctl restart autofs && systemctl status autofs'

clear ; cat <<EOF
 Login as ldapuser on client:
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~
 When the script is finished, then you can su or login as $ldapuser to local server,
 and see if you do not see any warning or error.


EOF
runit "su - $ldapuser"


clear ; cat <<EOF
 nfs mount check:
 ~~~~~~~~~~~~~~~~
 Now if we could login successfully as user $ldapuser, then
 we should see the nfs mount has been done by already configured autofs.


EOF

runit 'df -hT | grep nfs'

clear ; cat <<EOF
~~~~~~~~~~~~~~~~~
COMMANDS HISTORY:
~~~~~~~~~~~~~~~~~
rm -rf /etc/openldap && yum reinstall openldap -y
yum remove openldap-clients nss-pam-ldapd -y
yum install openldap-clients nss-pam-ldapd -y
authconfig --enableforcelegacy --update
authconfig --enableldap --enableldapauth --ldapserver="$ldap_server" --ldapbasedn="$domainctl" --update
authconfig --enablemkhomedir --update
authconfig --enableldaptls --ldaploadcacert="http://$ldapserver/pub/homeldap.cert" --update
echo 'tls_reqcert allow' >> /etc/nslcd.conf
tail /etc/nslcd.conf
systemctl enable nslcd.service && systemctl restart nslcd.service && systemctl status nslcd.service
getent passwd $ldapuser
ldapsearch -x cn=$ldapuser -b dc=home,dc=local
yum remove autofs nfs-utils -y && yum install autofs nfs-utils -y
systemctl start autofs && systemctl enable autofs && systemctl status autofs
showmount -e $ldapserver
ls /net/$ldapserver/ && df -Th | grep nfs
mkdir -p /home/ldap
cat /etc/auto.master.d/home.autofs
cat /etc/auto.home
systemctl restart autofs && systemctl status autofs
su - $ldapuser
df -hT | grep nfs
EOF

echo
echo OPEERATION COMPLETED!
echo

# CLOSING MAIN BODY

