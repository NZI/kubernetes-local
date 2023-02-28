#!/bin/bash
timestamp=$(date +%s)

VM_NAME="kubernetes_router_test"
KUBERNETES_INTNET="kubernetes"

VDI_PREFIX="${VM_NAME}_preload"
VM_LOCATION="$PWD/.virtualbox/$VM_NAME"
PRELOAD_VDI="$VM_LOCATION/${VDI_PREFIX}-${timestamp}.vdi"


## Download CHR
if [[ ! -f chr.vdi ]]; then
  echo "Downloading Cloud Hosted Router for VirtualBox"
  v = ""
  while [[ -z $v ]]; do
    v=$(echo $(curl -Ls https://mikrotik.com/download --output - | grep -oE "<th>.* Stable</th>" | grep -oE "(\d+\.?)+ " | sort | tail -n 1))
  done
  echo "CHR Version: $v"

  curl -L -o chr-$v.vdi.zip https://download.mikrotik.com/routeros/$v/chr-$v.vdi.zip
  unzip chr-$v.vdi.zip
  mv chr-$v.vdi chr.vdi

  rm chr-$v.vdi.zip
fi


## Build provisioning drive
(
  # sometimes the docker image cannot access loop devices, just loop until it can
  while ! docker-compose up --exit-code-from mikrotik_build; do
    sleep 1;
  done
  VBoxManage convertfromraw ./build/mikrotik.img $PRELOAD_VDI

) &


### Setup and power off vm
(
  if vboxmanage list vms | grep -q "\"$VM_NAME\""; then
    vboxmanage controlvm "$VM_NAME" poweroff
    sleep 3
    VBoxManage unregistervm "$VM_NAME" --delete-all
  fi

  sleep 1
  diskLocation="$VM_LOCATION/$VM_NAME.vdi"
  echo $diskLocation

  mkdir -p $VM_LOCATION
  VBoxManage createvm \
    --name="$VM_NAME" \
    --ostype=Linux_64 \
    --register \
    --basefolder=$VM_LOCATION

  VBoxManage modifyvm "$VM_NAME" --memory=2048 --cpus=2
  VBoxManage modifyvm "$VM_NAME" --nic1 nat 
  VBoxManage modifyvm "$VM_NAME" --nic2 intnet --intnet2=$KUBERNETES_INTNET
  
  cp chr.vdi "$diskLocation"
  VBoxManage internalcommands sethduuid "$diskLocation"

  VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci       
  VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$diskLocation"
  VBoxManage modifyvm "$VM_NAME" --boot1 disk --boot2 none --boot3 none --boot4 none 

) &

wait

### Attach preloaded disk and boot vm

VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 1 --device 0 --type hdd --medium "$PRELOAD_VDI"
vboxmanage startvm "$VM_NAME"  --type headless

# Periodically screenshot vm and look for the login prompt with tesseract
while ! grep -q "RouterOS Login:" .virtualbox/"$VM_NAME"/screentext.txt; do
  VBoxManage controlvm "$VM_NAME" screenshotpng .virtualbox/"$VM_NAME"/screenshot.png
  tesseract .virtualbox/"$VM_NAME"/screenshot.png .virtualbox/"$VM_NAME"/screentext 2>/dev/null
  cat .virtualbox/"$VM_NAME"/screentext.txt
  sleep 1
done

rm .virtualbox/"$VM_NAME"/screenshot.png
rm .virtualbox/"$VM_NAME"/screentext.txt

# https://www.win.tue.nl/~aeb/linux/kbd/scancodes-1.html
# send login command
#                                                   a     d     m     i     n     \n    \n
VBoxManage controlvm "$VM_NAME" keyboardputscancode 1e 9e 20 a0 32 b2 17 97 31 b1 1c 9c 1c 9c;
sleep 0.5;
# send import command
#                                                   /     i     m     p     o     r     t     [ ]   d     \t    \n
VBoxManage controlvm "$VM_NAME" keyboardputscancode 35 b5 17 97 32 b2 19 99 18 98 13 93 14 94 39 b9 20 a0 0f 8f 1c 9c