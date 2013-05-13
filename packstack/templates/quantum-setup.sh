#!/bin/bash

 . /root/keystonerc_admin 
 . /tmp/answers.txt
 
PUBLIC_IP={{ ansible_ec2_public_ipv4 }} 
PRIVATE_IP={{ ansible_eth0.ipv4.address }}
if [ "$1" = server ]; then

  quantum-server-setup --yes \
                       --plugin openvswitch \
                       --user quantum \
                       --rootpw ${CONFIG_MYSQL_PW} 
fi
                                       
if [ "$1" = dhcp ]; then
  quantum-dhcp-setup --plugin openvswitch --qhost ${PRIVATE_IP}
fi

if [ "$1" = l3 ]; then
  quantum-l3-setup   --plugin openvswitch --qhost ${PRIVATE_IP}
fi        
