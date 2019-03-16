#!/bin/bash

# Author: bm-zi
# PROGRAM TO MANAGE LVM AND SWAP PARTITION

# DEFINED VARIABLES
b=$(tput smso)
n=$(tput rmso)

function input_ok(){
   var_name=`echo $1`; read -p "[$var_name]: " val
   read -p 'Confirm? [y|n] ' ans
   if [[ ! $ans =~ "y"  ]]; then
      input_ok $var_name
   fi
   
   # when the function is called with a variable name as argument,
   # when user confirms then the '$val' is set as the final value 
   # for that variable. 
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
          exec $(readlink -f "$0")
          ;;
       *)
          echo "You didn't choose any disk!"
          ;;
     esac
done
}

### f8
function update_fstab () {
  echo; echo 'partitions available'; part_list=($(lsblk -l | grep part | awk '{print $1}') 'quit')
  select part in "${part_list[@]}"
    do
      case $part in
        quit) exec $(readlink -f "$0");;
           *) partition=/dev/$part; echo; echo selected partition: $partition; uuid=$(blkid -o value -s UUID $partition); fstype=$(blkid -o value -s TYPE $partition);
              printf 'Enter the mount point '; input_ok Dir; Dir=$val; mkdir -p $Dir; echo 'Following entry will be added to fstab file:'; 
              entry="UUID=$uuid $Dir $fstypy defaults 0 0"; echo "$entry"; read -p 'Press any key to continue '; echo "$entry" >> /etc/fstab;
              vim /etc/fstab; cmds=("mount -a" "echo \"mkfs.xfs $partition\""); run_cmds "${cmds[@]}"; read -p 'Press any key to continue '; exec $(readlink -f "$0")
      esac
    done
 
}

function run_cmd (){
   a="$1"


        echo
        echo "..............................................."
        echo "Enter to run the following command or q to quit"
        echo "..............................................."
        read -p "# $a " input
        if [[ $input =~ "q" ]]; then return 0 ; fi
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

### f7
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


function digit_check (){
if ! [[ "$1" =~ ^[0-9]+$ ]]
    then
       return 1
    else
       return 0
fi
}

### f6
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
   
cat<<EOF
Note
~~~~
A new swap partition with has been created by
command fdisk with following sequence
n Enter Enter Enter $swapsize t Enter 82 w
EOF
echo
fdisk $disk_selected <<EOF &>/dev/null
n



$swapsize
t

82
w
EOF
partprobe &>/dev/null
echo "Result:"
fdisk -l /dev/$disk | grep -E ^/dev


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

### f1
function fdisk_fct (){

echo Available Disks and Partitions:
echo ...............................
lsblk
echo

select_disk
if [[ $disk == ?d? ]]; then 
   clear
   echo "# fdisk $disk_selected"
   fdisk $disk_selected
   run_cmd "partprobe"
fi
}



function part_info (){
   clear
   echo 
   echo 'list block devices'
   echo '..................'
   lsblk | grep -Ei '(disk|part)'
   echo
   echo 'disk partition table'
   echo '....................'
   fdisk -l|grep Disk|grep dev
   echo
   echo 'information about volume groups'
   echo '...............................'
   vgs
   echo
   echo 'information about logical volumes'
   echo '.................................'
   lvs
   echo
   echo 'information about swap'
   echo '......................'
   swapon -a   
   swapon -s
   echo
} 

### f4
function lv_create () {
  echo "Select from available VG's: "; vgs=($(vgs | tail -n +2 | awk '{print $1}') 'help' 'quit')
  select vg in "${vgs[@]}"
    do
      case $vg in
        quit) exec $(readlink -f "$0");;
        help) 
cat <<EOF

 Information about selecting the size
 ------------------------------------ 
 -L, --size LogicalVolumeSize[bBsSkKmMgGtTpPeE]

 Examples of volume size:
 100M
 2048K
 2G 

EOF
              read -p 'Press any key to continue'; echo;;
           *) echo You selected: $vg; echo; echo VG information:; eval vgdisplay $vg;
              printf 'Enter logical volume name '; input_ok lvname; lvname=$val; printf 'Enter logical volume size '; input_ok lvsize; lvsize=$val
              cmd="lvcreate -n $lvname -L ${lvsize}M $vg"; echo $cmd; echo; cmd="lvdisplay /dev/$vg/$lvname"; echo "$lvname information:"; eval $cmd; echo
              read -p 'Press any key to contine'; exec $(readlink -f "$0");;
      esac
    done
}



function vg_create_command (){
  echo; echo 'partitions available'; part_list=($(lsblk -l | grep part | awk '{print $1}') 'quit')
  select part in "${part_list[@]}" 
    do
      case $part in
        quit) exec $(readlink -f "$0");;
           *) partition=/dev/$part; echo; echo selected partition: $partition; printf 'Enter volume group name '; input_ok vgname; vgname=$val; printf 'Enter volume group size '; input_ok vgsize; vgsize=$val
              cmd="vgcreate -s ${vgsize}M $vgname $partition"; echo Command to be executed: ; echo $cmd; echo Available VGs: ; eval vgs; read -p 'Press any key to contine'; exec $(readlink -f "$0");;
      esac 
    done
}

### f2
function vg_create () {
echo A partiotion is required for volume group:
  select part in 'create a new partition' 'use existing partition' 'quit'; do
    case $part in
      cre*) fdisk_fct; vg_create_command break;;
      use*) vg_create_command break;; 
         *) exec $(readlink -f "$0");;
    esac; done
}


function vgextend_cmd () {
vgname=$1
select ext in "extend to maximum available" "extend by specified size" "quit"
  do
  case $ext in
    quit) exec $(readlink -f "$0");;
    *maximum*) echo volume $vgname will be extended to maximum available space;;
    *size) printf "Enter the size of $vgname to be extended "; input_ok vg_size; vgsize=$val;
  esac
  done
}

### f3
function vg_extend () {
  echo 'Select volume group to be extended:'; vgs=($(vgs | tail -n +2 | awk '{print $1}') 'quit')
  select vg in "${vgs[@]}"
    do
      case $vg in
        quit) exec $(readlink -f "$0");;
           *) echo You selected: $vg; echo; echo VG information:; eval vgdisplay $vg; 
              vgextend_cmd $vg
              read -p 'Press any key to contine'; exec $(readlink -f "$0");;
      esac
    done
}


function selected_item (){
   selected=$1
   if [[ $selected =~ 'fdisk command' ]] ; then fdisk_fct
   elif [[ $selected =~ 'vg creation' ]]; then vg_create
   elif [[ $selected =~ 'vg extentsion' ]] ; then vg_extend 
   elif [[ $selected =~ 'lv creation' ]]; then lv_create
   elif [[ $selected =~ 'lv extension' ]]; then echo 'lv extension  has been selected'
   elif [[ $selected =~ 'add swap' ]]; then add_swap
   elif [[ $selected =~ 'remove swap' ]]; then rem_swap
   elif [[ $selected =~ 'update fstab' ]]; then update_fstab 
   elif [[ $selected =~ 'partition information' ]]; then part_info
   elif [[ $selected =~ 'quit' ]]; then echo exiting program ...; exit 0
   else  echo 'Cannot recognize the function!'
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
            'partition information'
            'quit'
)

menu_from_array "${operations[@]}"
