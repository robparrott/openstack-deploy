#!/bin/bash


O_IP={{ ansible_eth0.ipv4.address }}
T_IP={{ ansible_ec2_public_ipv4 }}
ANS_FILE=/tmp/answers.txt

# generate an answers file if not present
[ -f /tmp/answers.txt ] || packstack --gen-answer-file=/tmp/answers.txt

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

   perl -i -p -e "s/${KEY}=${O_IP}/${KEY}=${T_IP}/g" ${ANS_FILE}
   
done

#
# Fix the interface
#
perl -i -p -e 's/eth1/lo/g' ${ANS_FILE}