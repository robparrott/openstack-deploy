#!/bin/bash

 . /root/keystonerc_admin 
 . /root/packstack-answers-current.txt
 
if [ "$1" = server ]; then

  quantum-server-setup --yes \
                       --plugin openvswitch \
                       --user quantum \
                       --rootpw ${CONFIG_MYSQL_PW} 
fi
                       
if [ "$1" = dhcp ]; then
  quantum-dhcp-setup --plugin openvswitch --qhost 127.0.0.1
fi                      

if [ "$1" = dhcp ]; then
  quantum-dhcp-setup --plugin openvswitch --qhost 127.0.0.1
fi

if [ "$1" = l3 ]; then
  quantum-l3-setup --plugin openvswitch --qhost 127.0.0.1
fi        