#!/usr/bin/bash

# ABOUT THIS SCRIPT:
# THIS SCRIPT CONFIGURES NFS SHARE ON REDHAT/CENTOS 7.0.
# THE OPERATION WILL BE DONE STEP BY STEP, INTERACTING WITH YOU.
# WHEN YOU SEE THE PROMPT "# " THEN YOU CAN PRESS ENTER TO
# CONTINUE THE OPERATIONS.

# VARIABLES DEFINITION
b=$(tput smso)
n=$(tput rmso)


# FUNCTIONS START

# STOPS RUNNING SCRIPT, WHILE THE ARGUMENT 
# IS NOT EQUAL TO 'y' OR 'Y' OR 'Enter'
# #######################################
function userValid () {
while [[ $1 =~ [A-Xa-xzZ] ]]; do
   exit 0
done
}


# SHOW OS INFORMATION, BEFORE RUNNING SCRIPT
# ##########################################
function osCheck () {
if [ -f /etc/os-release ]; then
   echo This script tested on RHEL/CentOS 7.0 and higher.
   echo
   echo Your Operating System Information:
   echo ----------------------------------
   /usr/bin/cat /etc/os-release 
   echo -----------------------------
   printf 'Do you want to continue?[y|n] '
   read ans
   userValid $ans
fi
}


function runit () {
com=$1
echo COMMAND TO BE RUN:
#echo "$com" | sed 's/./~/g'
echo "${b}$com${n}"
#echo "$com" | sed 's/./~/g'
echo '[q]exit | [s]skip | [Enter]run?' ; echo
printf '# ' ; read confirmation 

if [[ $confirmation =~ 'q' ]]; 
   then exit 0
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

# STOPS RUNNING SCRIPT, WHILE THE ARGUMENT 
# IS NOT EQUAL TO 'y' OR 'Y' OR 'Enter'
# ########################################
function userValid () {
while [[ $1 =~ [A-Xa-xzZ] ]]; do
   exit 0
done
}

# CHECKING THE SHARED DIRECTORY
# #############################
function nfsdir () {
/usr/bin/clear
printf 'Enter directory name for nfs share: ' ; read DIRECTORY
if [ -d "$DIRECTORY" ] ; then
   printf "\"$DIRECTORY\" exists, Do you want to be used as nfs share? [y|n] " ; read ans

   if [[ ! $ans =~ [A-Xa-xzZ] ]] ; then
      mydir=$DIRECTORY
      printf "Your shared directory will be \"$mydir\"?[y|n] " ; read ans ; userValid $ans
   else 
      echo
      nfsdir  
   fi

elif [[ ! $DIRECTORY = \/* ]] ; then
   echo
   echo Provide directory with full path !!   
   nfsdir	

else
   mydir=$DIRECTORY
   printf "Your shared directory will be \"$mydir\"?[y|n] " ; read ans ; userValid $ans
   runit "mkdir -p $mydir"
fi
}


# VALIDATE FORMAT OF A GIVEN IP ADDRESS
# #####################################
function validIP()
{
   local  ip=$1
   local  stat=1

   if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
       OIFS=$IFS
       IFS='.'
       ip=($ip)
       IFS=$OIFS
       [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
           && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
       stat=$?
   fi
   return $stat
}


# FUNCTIONS END




# STARTING MAIN BODY

clear
echo "${b}Configuring nfs server on RHEL 7 or CentOS 7${n}"
sleep 1 
osCheck ; clear

#if ! rpm -qa nfs-utils; then
runit 'yum remove nfs-utils -y  && yum install nfs-utils -y' ; clear
runit '/usr/bin/systemctl start nfs-server.service && /usr/bin/systemctl enable nfs-server' ; clear
#fi

if ! /usr/bin/systemctl status firewalld &> /dev/null ; then
   runit '/usr/bin/systemctl status firewalld' ; clear
   runit 'firewall-cmd --permanent --zone=public --add-service=nfs --add-service=mountd --add-service=rpc-bind'
   clear; runit 'firewall-cmd --reload'
fi

cat <<EOF
Information:
~~~~~~~~~~~~
At this step you need to provide two item:
- directory name that you want to share with others.
- ip address of server(s) that will access the shared directory.


EOF
printf '# ' ; read x ; nfsdir

clear ; printf "Enter IP address of server(s) that get access to $mydir: " ; read ips

while  ! validIP $ips ; do
clear; printf 'Enter a valid IP: ' ; read ips
done
 
if [[ $ips == *"/"* ]]; then
   gtw=${ips#*/} 
   ip=${ips%/*}
   if validIP $ip; then
      str="$ip/$gtw"
      echo "$mydir $str(rw,sync,no_root_squash,no_all_squash)" >> /etc/exports
      echo "Editing file /etc/exports in vi " 
      printf "Please wait !!! "; sleep 3
      vi /etc/exports
   fi
else 
   ip=$ips
   if validIP $ip; then
      str="$ip"
      echo "$mydir $str(rw,sync,no_root_squash,no_all_squash)" >> /etc/exports
      echo "Editing file /etc/exports in vi" ; 
      printf "Please wait !!! "; sleep 3
      vi /etc/exports
   fi

fi

clear; runit 'cat /etc/exports' ; clear
runit 'systemctl restart nfs-server && systemctl status nfs-server'; clear
echo
echo 'All operations completed!'
echo

# CLOSING MAIN BODY


