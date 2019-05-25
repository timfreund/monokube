#!/usr/bin/env bash

which apt 2>&1 >/dev/null
if [ $? -eq 0 ]
then
    apt install -y cloud-image-utils git genisoimage libvirt-bin libvirt-clients ruby qemu virtinst
fi

which yum 2>&1 >/dev/null
if [ $? -eq 0 ]
then
    yum install -y git genisoimage libvirt-daemon-config-network libvirt-daemon-kvm ruby qemu virt-install
fi

