#!/usr/bin/env bash

. monokube.env

echo "[monokube]" > cluster/inventory

for idx in `seq 1 ${VM_COUNT}`;
do
    node_name=monokube-${idx}
    virsh domstate ${node_name} | grep running >/dev/null
    if [ $? -eq 0 ]
    then
        interfaces=`virsh domifaddr ${node_name} | grep : | head -1 | wc -l`
        while [ $interfaces -eq 0 ]
        do
            sleep 2
            interfaces=`virsh domifaddr ${node_name} | grep : | head -1 | wc -l`
        done
        ip=`virsh domifaddr ${node_name} | grep : | sed -e 's/.* //' -e 's|/.*||'`
        echo "${node_name} ansible_host=${ip}" >> cluster/inventory
    else
        echo "${node_name} isn't running, can't inspect interface state"
    fi
done


cat >>cluster/inventory<<EOF

[monokube:vars]
ansible_user=monokube
ansible_ssh_private_key_file=./.ssh/id_rsa
ansible_ssh_common_args="-oStrictHostKeyChecking=no"
ansible_python_interpreter=/usr/bin/python3

EOF
