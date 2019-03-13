#!/bin/bash

# Author: bm-zi
# PROGRAM TO MANAGE LVM AND SWAP PARTITION

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

function update_fstab () { 
vim /etc/fstab
}

function run_cmd (){
   a="$1"


        echo
        echo "..............................................."
        echo "Enter to run the following command or q to quit"
        echo "..............................................."
        read -p "# $a " input
        if [[ $input =~ "q" ]]; then break; fi
        eval $a

}

function rem_swap_partition (){
echo
select_disk
disk="/dev/$disk"
disk_nr=$(fdisk -l /dev/vda | grep -E ^/dev | grep 'vda3' | awk '{print $1}' | grep -Eo '[0-9]')

cat<<EOF

The swap partition $swappart will be deleted by fdisk command,"
with the following sequence:
d $disk_nr w

EOF


fdisk $disk <<EOF &>/dev/null
d
$disk_nr
w
EOF
partprobe &>/dev/null
echo "fdisk completed!"
echo "Result:"
fdisk -l $disk | grep -E ^/dev
}

function rem_swap () { 
echo Available swap partitions:
swapparts=($(swapon -s | awk '{print $1}' | awk '{if(NR>1)print}') "quit")
select swappart in "${swapparts[@]}"
do
   case $swappart in
   quit)
      break
      ;;
   *)
      echo You are about to remove swap $swappart
      read -p 'Confirm [Enter] or quit[q] ' input

      if [[ $input =~ "q" ]]; then 
         break         
      else  
         eval "swapoff $swappart"
         eval "vim /etc/fstab"
         echo
         echo Available swap after removal:
         echo .............................
         swapon -s
         echo
         rem_swap_partition
       fi
       break
       ;;
  
     esac
done
}



function run_cmds (){
    a=("$@")
    echo
    echo ............................................. 
    echo Following commands will be executed in order:
    echo ............................................. 
    index=1
    for i in "${a[@]}" ; do
        echo "$index- $i"
        index=$(($index + 1))
    done

    for i in "${a[@]}" ; do
        echo
        echo "..............................................."
        echo "Enter to run the following command or q to quit"
        echo "..............................................."
        read -p "# $i " input
        if [[ $input =~ "q" ]]; then break; fi
        eval $i 
    done

}


function fdisk_newswap () {
disk="$1"
cat<<EOF
A new swap partition with fdisk command will be created,"
with the following sequence:
n p Enter Enter $swapsize t Enter 82 w
EOF
echo 
fdisk /dev/$disk <<EOF &>/dev/null
n
p


$swapsize
t

82
w
EOF
partprobe &>/dev/null
echo "fdisk completed!"
echo "Result:"
fdisk -l /dev/$disk | grep -E ^/dev
}

function digit_check (){
if ! [[ "$1" =~ ^[0-9]+$ ]]
    then
       return 1
    else
       return 0
fi
}

function add_swap() {
echo
select_disk
echo
echo "Check free space available on $disk from following: "
lsblk /dev/$disk | grep -Ei "disk|part"
echo
read -p 'Enter the swap size in megabyte: ' ss

if digit_check $ss; then
   swapsize="+${ss}M"
   
   fdisk_newswap "$disk"

   swapdisk=$(fdisk -l /dev/vda | grep -E ^/dev | tail -1 | awk '{print $1}')
   cmd="mkswap $swapdisk"
   run_cmd "$cmd"
   diskuid=$(blkid  $swapdisk | awk '{print $2}')
   fstabEntry="$diskuid swap swap defaults 0 0"

   declare -a cmds=(   "echo $fstabEntry >> /etc/fstab"
   "tail -1 /etc/fstab"
   "swapon -a"
   "mount -a"
   "lsblk /dev/$disk | grep -Ei '(disk|part)'"
   "swapon -s")

run_cmds "${cmds[@]}"
   
else
   read -p 'Only digits!'
   add_swap
fi
}


function fdisk_fct (){
select_disk
if [[ $disk == ?d? ]]; then 
   fdisk $disk_selected
   partprobe &>/dev/null
fi
}



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
   echo;echo
   echo 'information about swap'
   echo '......................'
   swapon -a   
   swapon -s
   echo
} 


function selected_item (){
   selected=$1
   if [[ $selected =~ 'fdisk command' ]] ; then
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
      rem_swap
   elif [[ $selected =~ 'update fstab' ]]; then
      update_fstab 
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
operations=('fdisk command' 
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
