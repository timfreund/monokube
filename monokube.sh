#!/usr/bin/env bash

. monokube.env

IMAGE_NAME=`echo ${IMAGE_URL} | sed -e 's|.*/||'`

pool_count=`virsh pool-list | grep ${LIBVIRT_POOL_NAME} | wc -l`
if [ ${pool_count} -eq 0 ]; then
    echo "Your chosen storage pool (${LIBVIRT_POOL_NAME}) does not exist."
    echo "Create it with 'virsh pool-create' or 'virt-manager'"
    exit 1
fi

net_count=`virsh net-list | grep ${LIBVIRT_NET_NAME} | wc -l`
if [ ${net_count} -eq 0 ]; then
    echo "Your chosen network (${LIBVIRT_NET_NAME}) does not exist."
    echo "Create it with 'virsh pool-create' or 'virt-manager'"
    exit 1
fi

img_count=`virsh vol-list ${LIBVIRT_POOL_NAME} | grep ${IMAGE_NAME} | wc -l`
if [ ${img_count} -eq 0 ]; then
    if [ ! -f ${IMAGE_NAME} ]
    then
        echo "Downloading source image"
        curl --output ${IMAGE_NAME} ${IMAGE_URL}
    fi
    echo "Creating source volume from image"
    virsh vol-create-as --pool ${LIBVIRT_POOL_NAME} --name ${IMAGE_NAME} --capacity 0 --format qcow2
    virsh vol-upload --vol ${IMAGE_NAME} --file ${IMAGE_NAME} --pool ${LIBVIRT_POOL_NAME}
fi

for idx in `seq 1 ${VM_COUNT}`;
do
    node_name=monokube-${idx}
    node_img=${node_name}.img

    dom_count=`virsh list --all | grep ${node_name} | wc -l`
    if [ ${dom_count} -eq 0 ]
    then
        echo "Building ${node_name}"
        virsh vol-clone --vol ${IMAGE_NAME} --newname ${node_img} --pool default
        virsh vol-resize ${node_img} ${VM_DISK}G --pool ${LIBVIRT_POOL_NAME}
        virt-install --name ${node_name} \
                     --memory ${VM_MEMORY} --vcpus ${VM_CPU} \
                     --import \
                     --disk vol=${LIBVIRT_POOL_NAME}/${node_img},bus=sata \
                     --check path_in_use=off \
                     --network network=${LIBVIRT_NET_NAME} \
                     --noautoconsole
    else
        echo "Skipping ${node_name} creation, already exists"
        running_count=`virsh list --all | grep ${node_name} | grep running | wc -l`
        if [ ${running_count} -eq 0 ]
        then
            echo "Starting ${node_name}"
            virsh start ${node_name}
        fi
    fi
done    

# --serial file,path=/tmp/${name}.log \
    # --disk vol=${LIBVIRT_POOL_NAME}/sonicpi-userdata.img,device=cdrom \
