#!/usr/bin/env bash

#
# Fix tgtd for volumes
#
sudo mv /etc/tgt/tgtd.conf /etc/tgt/tgtd.conf.backup
sudo su - -c "echo default-driver iscsi >> /etc/tgt/tgtd.conf"
sudo su - -c "echo include /opt/stack/data/cinder/volumes/* >> /etc/tgt/tgtd.conf"
sudo service tgtd restart 

# Sample ``local.sh`` for user-configurable tasks to run automatically
# at the sucessful conclusion of ``stack.sh``.

# NOTE: Copy this file to the root ``devstack`` directory for it to
# work properly.

# This is a collection of some of the things we have found to be useful to run
# after ``stack.sh`` to tweak the OpenStack configuration that DevStack produces.
# These should be considered as samples and are unsupported DevStack code.


# Keep track of the devstack directory
TOP_DIR=$(cd $(dirname "$0") && pwd)

# Import common functions
source $TOP_DIR/functions

# Use openrc + stackrc + localrc for settings
source $TOP_DIR/stackrc

# Destination path for installation ``DEST``
DEST=${DEST:-/opt/stack}


# Import ssh keys
# ---------------

# Import keys from the current user into the default OpenStack user (usually
# ``demo``)

# Get OpenStack auth
source $TOP_DIR/openrc

# Add first keypair found in localhost:$HOME/.ssh
for i in $HOME/.ssh/id_rsa.pub $HOME/.ssh/id_dsa.pub; do
    if [[ -r $i ]]; then
        nova keypair-add --pub_key=$i `hostname`
        break
    fi
done


# Create A Flavor
# ---------------

# Get OpenStack admin auth
source $TOP_DIR/openrc admin admin

# Name of new flavor
# set in ``localrc`` with ``DEFAULT_INSTANCE_TYPE=m1.micro``
MI_NAME=m1.micro

# Create micro flavor if not present
if [[ -z $(nova flavor-list | grep $MI_NAME) ]]; then
    nova flavor-create $MI_NAME 6 128 0 1
fi

#
# Setup a separate set of resources
#
------------------------------

source $TOP_DIR/openrc admin admin

# Set values
PROJECT={{ test_project_name }}
USERNAME={{ test_username }}
PASSWD={{ test_user_password }}
EMAIL={{ test_user_email }}
PROJECT_NET_NAME=test_net
PROJECT_ROUTER_NAME=test_router

# Create a project and get its ID
keystone tenant-create --name ${PROJECT}
PROJECT_ID=$( keystone tenant-list | grep ${PROJECT} | awk '{print $2}' )

# Create a new user and assign the member role 
#  to it in the new tenant (keystone role-list to get the appropriate id):

keystone user-create --name=${USERNAME} --pass=${PASSWD} --tenant-id ${PROJECT_ID} --email=${EMAIL}
USER_ID=$( keystone user-list | grep ${USERNAME} | awk '{print $2}' )
ROLE_ID=$( keystone role-list | grep Member      | awk '{print $2}' )
keystone user-role-add --tenant-id ${PROJECT_ID} --user-id ${USER_ID} --role-id ${ROLE_ID}

# Create a new network for the tenant:

quantum net-create --tenant-id ${PROJECT_ID} ${PROJECT_NET_NAME}

# Create a new subnet inside the new tenant network:

quantum subnet-create --tenant-id ${PROJECT_ID} ${PROJECT_NET_NAME} 50.50.1.0/24

# Create a router for the new tenant:

quantum router-create --tenant-id  ${PROJECT_ID} ${PROJECT_ROUTER_NAME}
ROUTER_ID=$( quantum router-list | grep ${PROJECT_ROUTER_NAME} | awk '{print $2}' )

# Add the router to the running l3 agent:

L3_AGENT_ID=$( quantum agent-list | grep "L3 agent" | awk '{print $2}' )
quantum l3-agent-router-add ${L3_AGENT_ID}  ${PROJECT_ROUTER_NAME}

# Add the router to the subnet:
quantum router-interface-add ${PROJECT_ROUTER_ID} ${SUBNET_ID}




# Setup some security groups
# ----------

quantum security-group-create  --tenant-id ${PROJECT_ID}  webservers --description "security group for webservers"
SEC_GROUP_ID=$( quantum security-group-list | grep webservers | awk '{print $2}' )

# Creating security group rule to allow web access
quantum security-group-rule-create --tenant-id ${PROJECT_ID} --direction ingress --protocol icmp --port_range_min -1 --port_range_max -1  --remote-ip-prefix 0.0.0.0/0 ${SEC_GROUP_ID}
quantum security-group-rule-create --tenant-id ${PROJECT_ID} --direction ingress --protocol tcp --port_range_min 22  --port_range_max 22  --remote-ip-prefix 0.0.0.0/0 ${SEC_GROUP_ID}
quantum security-group-rule-create --tenant-id ${PROJECT_ID} --direction ingress --protocol tcp --port_range_min 80  --port_range_max 80  --remote-ip-prefix 0.0.0.0/0 ${SEC_GROUP_ID}
quantum security-group-rule-create --tenant-id ${PROJECT_ID} --direction ingress --protocol tcp --port_range_min 443 --port_range_max 443 --remote-ip-prefix 0.0.0.0/0 ${SEC_GROUP_ID}

#
# FIXES
#
#sudo echo "include /opt/stack/data/cinder/volumes/*" >> /etc/tgt/tgtd.conf
#sudo service tgtd restart