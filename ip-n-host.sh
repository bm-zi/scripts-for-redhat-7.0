#!/usr/bin/bash

# Author: bm-zi

# ABOUT THIS SCRIPT:
# THIS SCRIPT CONFIGURES IP AND HOSTNAME ON REDHAT/CENTOS 7.0.
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
   #clear
   echo "# $com" 
   sleep 1
   /bin/bash -c "$com"
   printf "# " ; read x
fi
}

# FUNCTIONS END



# STARTING MAIN BODY
clear
echo "${b}CONFIGURING IP AND HOSTNAME ON REDHAT/CENTOS 7.0${n}"

cat <<EOF

 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Operations to be done in Summary:
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 We use hostnamectl and nmcli commands to setup IP and hostname.
 DNS server and gateway server are assumed to be the same server.

EOF

printf 'Enter serevr host name: ' ; read hn 
printf 'Enter server IP address[format: xxx.xxx.xxx.xxx/xx]: '; read ip
sleep 1
clear

str=$(echo $ip | awk -F  "/" '/1/ {print $1}')
gw=$(echo $str | awk -F "." '{print  $1"."$2"."$3".1"}')


cat <<EOF
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 Confirm highlighted information:
 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 hostname: ${b}$hn${n} 

 ip/gw: ${b}$ip${n}

 gateway:${b}$gw${n}

EOF

printf ' Confirm?[y|n] ' ; read ans;
if [[ $ans =~ [nN] ]]; then exit 0; fi

clear; cat <<EOF
 Setting host name
 ~~~~~~~~~~~~~~~~~
 First set the server name.
 On next login you will see the new server name.

EOF

runit "hostnamectl set-hostname $hn && hostnamectl"

clear; cat <<EOF
 Set up IP Address 
 ~~~~~~~~~~~~~~~~~
 - NetworkManager is the package including command nmcli and has to be installed!
   (If not installed, then script prompts for installtion.)
 - Once making sure NetworkManager is enabled and running, then start to configure 
   the IP address.

EOF
if ! rpm -q NetworkManager &> /dev/null; then
echo
echo 'NetworkManger not installed !!!'
echo
runit 'yum -y install NetworkManager'
fi

runit 'systemctl restart NetworkManager && systemctl status NetworkManager' ; clear

runit 'nmcli device status && echo && nmcli connection show'
echo
printf "Connection you want to delete? click 'Enter' if no connection to delete: " ; read con 
printf "Connection you want to add? click 'Enter' if no connection to add: " ; read mycon
echo
if [[ ! $con = "" ]] ; then runit "nmcli connection delete \"$con\" " ; fi 
echo

if [[ ! $mycon = "" ]] ; then runit "nmcli connection add con-name \"$mycon\" type ethernet ifname eth0 autoconnect yes ip4 $ip gw4 $gw"

runit 'nmcli device status && echo && nmcli connection show'
 
clear ; cat <<EOF 
 Modify connection:
 ~~~~~~~~~~~~~~~~~ 
 Change DNS and bring up "$mycon" and finally check the connection 
 and IP address.

EOF
runit "nmcli connection modify \"$mycon\" ipv4.method manual ipv4.dns $gw"
runit "nmcli connection up \"$mycon\""
fi
clear
runit 'nmcli device status && echo && nmcli connection show'
runit "hostname -I"

echo 
echo 'OPERATIONS COMPLETED'
echo
