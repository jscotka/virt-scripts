#!/bin/bash

# example: ./auto_create_vm.sh cockpit ~/build

prog=`basename $0`

function printh() {
    echo -e "Usage: $prog "
    echo " <postfix> [dir] [customization_script]"
    echo "    postfix:                it create output name in format like fedora21-suffix"
    echo "    dir:                  where to create/store images [optional]"
    echo "    customization_script: do customization script on guests [optional]"

}
if [ "$#" -lt 1 ]; then
    printh;
    exit 255
fi

POSTFIX=$1
test "$2" && DIR=$2 || DIR=/var/lib/libvirt/images
test "$3" && CUSTOMIZATION="--script '$3'"
ARCH=x86_64
TYPE=qcow2
mkdir -p $DIR


function create_parametrized(){
set -x
    DIST=$1
    REALDIST=$2
    REVISION=$3
    test "$4" && DISTOVERWRITE=$4 || DISTOVERWRITE=$DIST
    DOMAIN=$DIST-$POSTFIX
    ./create-guest-qcow2.bash $DOMAIN $REALDIST $ARCH $DIR
    sleep 5
    sudo virt-sysprep --connect qemu:///system -d $DOMAIN $CUSTOMIZATION
    DISCNAME="$DOMAIN.$TYPE"
    CDISCNAME="$DISCNAME.xz"
    UNSIZE=`stat $DIR/$DISCNAME -c "%s"`
    xz --best --block-size=16777216 $DIR/$DISCNAME
    COMSIZE=`stat $DIR/$CDISCNAME -c "%s"`
    SHASUM=`sha512sum $DIR/$CDISCNAME | cut -d ' ' -f 1`
    cat <<EOF >> $DIR/index
[$DOMAIN]
name=$DOMAIN
osinfo=$DISTOVERWRITE
arch=$ARCH
file=$CDISCNAME
revision=$REVISION
checksum=$SHASUM
format=$TYPE
size=$UNSIZE
compressed_size=$COMSIZE
EOF
set +x
}

create_parametrized fedora21 f21 1 fedora21
create_parametrized fedora22 f22 1 fedora21

if [ `gpg --list-keys | wc -l` -lt 4 ]; then
    echo "!!! your probably does not have generated gpg key, running command: gpg --gen-key"
    gpg --gen-key
fi
echo "Signing $DIR/index file"
gpg --clearsign --armor $DIR/index
