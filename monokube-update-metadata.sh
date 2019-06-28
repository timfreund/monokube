#!/usr/bin/env bash

. monokube.env

echo "[monokube]" > cluster/inventory

for idx in `seq 1 ${VM_COUNT}`;
do
    node_name=monokube-${idx}
    virsh domstate ${node_name} | grep running >/dev/null
    if [ $? -eq 0 ]
    then
	    macaddr=`virsh domiflist ${node_name} | grep : | head -1 | awk '{print $5}'`
	    ip=`arp -n | grep ${macaddr} | awk '{print $1}'`
	    while [[ -z "${ip}" ]]
	    do
	        sleep 2
	        echo "waiting"
	        ip=`arp -n | grep ${macaddr} | awk '{print $1}'`
	    done
        echo "${node_name} ansible_host=${ip}" >> cluster/inventory
    else
        echo "${node_name} isn't running, can't inspect interface state"
    fi
done

cat >>cluster/inventory<<EOF

[monokube:vars]
ansible_python_interpreter=/usr/bin/python3

EOF
