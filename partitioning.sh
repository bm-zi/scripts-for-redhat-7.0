#!/bin/bash

# Author: bm-zi
# PROGRAM TO MANAGE LVM AND SWAP PARTITION




function fdisk_fct (){
clear
select_disk
fdisk $disk_selected 
}


function select_disk() {
echo "Choose your disk"
echo "................"
disks=($(lsblk | grep disk | awk '{print $1}'))
options=($disks "quit")
PS3="Your choice: "

select dsk in "${options[@]}"
do
   case $dsk in
       vd*|sd*)
          disk_selected=/dev/$dsk
          break
          ;;
        *)
           echo "You didn't choose any disk!"
     esac
done
}

function part_layout (){
   clear; 
   echo 'list block devices'
   echo '..................'
   lsblk | grep -Ei '(disk|part)'
   echo;echo
   echo 'disk partition table'
   echo '....................'
   fdisk -l|grep Disk|grep dev
   echo;echo
   echo 'information about volume groups'
   echo '...............................'
   vgs
   echo;echo
   echo 'information about logical volumes'
   echo '.................................'
   lvs
} 


function selected_item (){
   selected=$1
   if [[ $selected =~ 'fdisk partitioning' ]] ; then
      fdisk_fct
   elif [[ $selected =~ 'vg creation' ]]; then
      echo 'vg creation has been selected'

   elif [[ $selected =~ 'vg extentsion' ]] ; then
      echo 'vg extentsion has been selected'

   elif [[ $selected =~ 'lv creation' ]]; then
      echo 'lv creation  has been selected'

   elif [[ $selected =~ 'lv extension' ]]; then
      echo 'lv extension  has been selected'

   elif [[ $selected =~ 'add swap' ]]; then
      echo 'add swap has been selected'

   elif [[ $selected =~ 'remove swap' ]]; then
      echo 'remove swap has been selected'

   elif [[ $selected =~ 'update fstab' ]]; then
      echo 'update fstab has been selected'

   elif [[ $selected =~ 'partition layout' ]]; then
      part_layout

   elif [[ $selected =~ 'quit' ]]; then
      echo exiting program ...
      exit 0
   else
      echo 'Cannot recognize the function!'
   fi
   echo;
   read -p 'Press Enter back to menu ' ans
   clear
   ./$(basename "$0") 
}

function menu_from_array (){
   clear
   echo '--- Available disk operatins ---'
   select item;
   do
      # Check the selected menu item number
      if [ 1 -le "$REPLY" ] && [ "$REPLY" -le $# ]; then
         echo "The selected item is $item";echo
         selected_item "$item"
         break;
      else
         echo "Wrong selection: Select any number from 1-$#"
      fi
   done
}


# LIST OF AVAILABLE OPERATIONS
operations=('fdisk partitioning' 
            'vg creation'
            'vg extentsion'
            'lv creation'
            'lv extension'
            'add swap'
            'remove swap'
            'update fstab'
            'partition layout'
            'quit'
)


menu_from_array "${operations[@]}"
