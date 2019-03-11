#!/bin/bash

# Author: bm-zi
# PROGRAM TO MANAGE LVM AND SWAP PARTITION

function add_swap() {
select_disk; echo
echo "Check free space available on $disk from following: "
lsblk /dev/$disk | grep -Ei "disk|part"
echo
read -p 'Enter the swap size in megabyte: ' ss
swapsize="+${ss}M"
echo "A new swap partition with fdisk command will be created,"
echo "with the following sequence:"
echo "n p Enter Enter $swapsize t Enter 82 w" ;echo
fdisk /dev/$disk <<EOF &>/dev/null 
n
p


$swapsize
t

82
w
EOF

partprobe &>/dev/null

echo "Result:"
lsblk /dev/$disk | grep -Ei "disk|part"

}


# Function for menu 1 
function fdisk_fct (){
select_disk
if [[ $disk == ?d? ]]; then 
   fdisk $disk_selected
fi
}

function select_disk() {
echo "Choose your disk"
echo "................"
disks=($(lsblk | grep disk | awk '{print $1}'))
disk_list=($disks "exit menu")
PS3="Your choice: "

select disk in "${disk_list[@]}"
do
   case $disk in
       vd*|sd*)
          disk_selected="/dev/$disk"
          break
          ;;
       exit*)
          echo "exiting this menu!"
          break
          ;;
       *)
          echo "You didn't choose any disk!"
          
          
          ;;
     esac
done
}

# Function for menu 9
function part_layout (){
   echo '..................'
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
      add_swap
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
         break
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
