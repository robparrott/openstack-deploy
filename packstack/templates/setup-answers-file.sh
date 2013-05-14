#!/bin/bash

O_IP={{ ansible_eth0.ipv4.address }}
T_IP={{ ansible_ec2_public_ipv4 }}
ANS_FILE=/tmp/openstack/answers.txt

# generate an answers file if not present
[ -f ${ANS_FILE} ] || packstack --gen-answer-file=${ANS_FILE}

#
# Use openstack-config tool to modify these files
#
CONFIG="openstack-config --set ${ANS_FILE} "

#
# edit to use public IPs for endpoints for services that need to be accessed from outside.
#
KEYS=" CONFIG_KEYSTONE_HOST \
       CONFIG_GLANCE_HOST \
       CONFIG_NOVA_API_HOST \
       CONFIG_NOVA_CERT_HOST \
       CONFIG_NOVA_VNCPROXY_HOST \
       CONFIG_SWIFT_PROXY_HOSTS \
       CONFIG_CINDER_HOST \
       CONFIG_HORIZON_HOST"

for KEY in $KEYS; do 

   ${CONFIG} general ${KEY} ${T_IP}
   #perl -i -p -e "s/${KEY}=${O_IP}/${KEY}=${T_IP}/g" ${ANS_FILE}
   
done

# Fix the interface for a single-node installation (use loopback)
${CONFIG} general CONFIG_NOVA_COMPUTE_PRIVIF lo
${CONFIG} general CONFIG_NOVA_NETWORK_PRIVIF lo

# Use Swift
${CONFIG} general CONFIG_SWIFT_INSTALL y

# Use HTTPS for horizon
${CONFIG} general CONFIG_HORIZON_SSL y
