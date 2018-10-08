#!/usr/bin/env bash

. monokube.env

for command in genisoimage erb virsh virt-install; do
    if ! which $command ; then
        echo "ERROR: Command not found: ${command}.  Exiting"
        exit 1
    fi
done

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
    echo "Create it with 'virsh net-create' or 'virt-manager'"
    exit 1
fi

if [ ! -d ./cluster ];
then
    mkdir -p ./cluster/.ssh
    chmod 700 ./cluster/.ssh
    ssh-keygen -N "" -C "monokube" -f ./cluster/.ssh/id_rsa > /dev/null
fi

img_count=`virsh vol-list ${LIBVIRT_POOL_NAME} | grep ${IMAGE_NAME} | wc -l`
if [ ${img_count} -eq 0 ]; then
    if [ ! -f ./cloud-images/${IMAGE_NAME} ]
    then
        echo "Downloading source image"
        mkdir -p ./cloud-images
        curl -L --output ./cloud-images/${IMAGE_NAME} ${IMAGE_URL}
    fi
    echo "Creating source volume from image"
    virsh vol-create-as --pool ${LIBVIRT_POOL_NAME} --name ${IMAGE_NAME} --capacity 0 --format qcow2
    virsh vol-upload --vol ${IMAGE_NAME} --file ./cloud-images/${IMAGE_NAME} --pool ${LIBVIRT_POOL_NAME}
fi

for idx in `seq 1 ${VM_COUNT}`;
do
    node_name=monokube-${idx}
    node_img=${node_name}.img
    node_userdata=${node_name}-userdata.img

    dom_count=`virsh list --all | grep ${node_name} | wc -l`
    if [ ${dom_count} -eq 0 ]
    then
        echo "Building ${node_name}"

        mkdir -p cluster/${node_name}/cloud-init
        erb node_name="${node_name}" ssh_public_key="`cat ./cluster/.ssh/id_rsa.pub`" cloud-init/user-data.erb > cluster/${node_name}/cloud-init/user-data
        echo "instance-id: $(uuidgen)" > cluster/${node_name}/cloud-init/meta-data
        # cloud-locads was used in previous versions of this script,
        # but that command is not available on RH variant systems. The
        # command is kept here as a reference for Debian user.  The genisoimage
        # command will work for all host operating systems
        # cloud-localds cluster/${node_name}/${node_userdata} cluster/${node_name}/cloud-init/user-data cluster/${node_name}/cloud-init/meta-data
        genisoimage -output cluster/${node_name}/${node_userdata} -volid cidata -joliet -rock cluster/${node_name}/cloud-init/user-data cluster/${node_name}/cloud-init/meta-data

        virsh vol-create-as --pool ${LIBVIRT_POOL_NAME} --name ${node_userdata} --capacity 0
        virsh vol-upload --vol ${node_userdata} --file cluster/${node_name}/${node_userdata} --pool ${LIBVIRT_POOL_NAME}

        virsh vol-clone --vol ${IMAGE_NAME} --newname ${node_img} --pool default
        virsh vol-resize ${node_img} ${VM_DISK}G --pool ${LIBVIRT_POOL_NAME}
        virt-install --name ${node_name} \
                     --memory ${VM_MEMORY} --vcpus ${VM_CPU} \
                     --import \
                     --disk vol=${LIBVIRT_POOL_NAME}/${node_img},bus=sata \
                     --disk vol=${LIBVIRT_POOL_NAME}/${node_userdata},device=cdrom \
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

