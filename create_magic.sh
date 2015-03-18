#!/bin/bash

ARCH=x86_64
TYPE=qcow2
DIR=~/build
mkdir $DIR
DIST=fedora21
DOMAIN=$DIST-cockpit
./create-guest-qcow2.bash $DOMAIN f21 x86_64 $DIR
sudo virt-sysprep --connect qemu:///system -d $DOMAIN
## there have to be another customization setup
DISCNAME="$DOMAIN.$TYPE"
CDISCNAME="$DISCNAME.xz"
UNSIZE=`stat $DIR/$DISCNAME -c "%s"`
xz --best --block-size=16777216 $DIR/$DISCNAME
COMSIZE=`stat $DIR/$CDISCNAME -c "%s"`
SHASUM=`sha512sum $DIR/$CDISCNAME | cut -d ' ' -f 1`

echo "
[$DOMAIN]
name=$DOMAIN
osinfo=$DIST
arch=$ARCH
file=$CDISCNAME
revision=1
checksum=$SHASUM
format=$TYPE
size=$UNSIZE
compressed_size=$COMSIZE
" > $DIR/index

gpg --clearsign --armor $DIR/index


