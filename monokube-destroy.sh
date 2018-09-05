#!/usr/bin/env bash

. monokube.env

IMAGE_NAME=`echo ${IMAGE_URL} | sed -e 's|.*/||'`

echo "Deleting cluster metadata"
rm -rf ./cluster

for idx in `seq 1 ${VM_COUNT}`;
do
    node_name=monokube-${idx}
    node_img=${node_name}.img
    echo "Destroying ${node_name} and volumes"
    virsh destroy ${node_name} >/dev/null 2>&1
    virsh undefine ${node_name} >/dev/null 2>&1
    virsh vol-delete --vol ${node_img} --pool ${LIBVIRT_POOL_NAME} >/dev/null 2>&1
    virsh vol-delete --vol ${node_name}-userdata.img --pool ${LIBVIRT_POOL_NAME} >/dev/null 2>&1
done
