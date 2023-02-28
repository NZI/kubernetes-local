#!/bin/bash

img='mikrotik.img'

# while true; do
#  echo 1;
#  sleep 5;
# done

cp /root/base.img ./$img

kpartxData=$(kpartx -av "$img")
echo "kpartxData = '"$kpartxData"'"

if [[ -z "$kpartxData" ]]; then
  exit 1
fi


loopDev=$(echo "$kpartxData" | awk '{print $3}')
echo "loopDev = '"$loopDev"'"



[[ -d /tmp/d ]] && rm -rf /tmp/d
mkdir -p /tmp/d
mount /dev/mapper/$loopDev /tmp/d

cp /app/src/mikrotik.rsc /tmp/d/mikrotik.rsc

umount /tmp/d
rm -rf /tmp/d
kpartx -dv "$img"
