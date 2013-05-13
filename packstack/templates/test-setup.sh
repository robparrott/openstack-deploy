#!/usr/bin/env bash


function get_k_id 
{
   RETVAL=$( keystone ${1}-list | grep ${2} | awk '{print $2}' )
   echo $RETVAL
}

function get_q_id 
{
   RETVAL=$( quantum ${1}-list | grep ${2} | awk '{print $2}' )
   echo $RETVAL
}


# Create A Flavor
# ---------------

# Get OpenStack admin auth
#source $TOP_DIR/openrc admin admin

# Name of new flavor
# set in ``localrc`` with ``DEFAULT_INSTANCE_TYPE=m1.micro``
MI_NAME=m1.micro

# Create micro flavor if not present
if [[ -z $(nova flavor-list | grep $MI_NAME) ]]; then
    nova flavor-create $MI_NAME 6 128 0 1
fi

#------------------------------
#
# Setup a separate set of test user objects
#
#------------------------------


# Set values from ansible

PROJECT={{ test_project_name }}
USERNAME={{ test_username }}
PASSWD={{ test_user_password }}
EMAIL={{ test_user_email }}
PROJECT_NET_NAME=test_net
PROJECT_SUBNET_NAME=test_subnet
PROJECT_ROUTER_NAME=test_router

# Create a project and get its ID

PROJECT_ID=$( get_k_id tenant ${PROJECT} )
if [ -z "$PROJECT_ID" ]; then
  keystone tenant-create --name ${PROJECT}
  PROJECT_ID=$( get_k_id tenant ${PROJECT} )
fi

# Create a new user and assign the member role 
#  to it in the new tenant (keystone role-list 
#   to get the appropriate id):

ROLE_ID=$( get_k_id role "Member" )
USER_ID=$( get_k_id user ${USERNAME}  )
if [ -z "$USER_ID" ]; then
  keystone user-create --name=${USERNAME} --pass=${PASSWD} --tenant-id ${PROJECT_ID} --email=${EMAIL}
  USER_ID=$( get_k_id user ${USERNAME}  )
  keystone user-role-add --tenant-id ${PROJECT_ID} --user-id ${USER_ID} --role-id ${ROLE_ID}
fi

#------------------------------
#
# Create networks for the test user
#
#------------------------------

# Create a new network for the tenant:

PROJECT_NET_ID=$( get_q_id net ${PROJECT_NET_NAME} )
if [ -z "$PROJECT_NET_ID" ]; then
  quantum net-create --tenant-id ${PROJECT_ID} ${PROJECT_NET_NAME}
  PROJECT_NET_ID=$( get_q_id net ${PROJECT_NET_NAME} )
fi
  
# Create a new subnet inside the new tenant network:

CIDR="50.50.1.0/24"
PROJECT_SUBNET_ID=$( get_q_id subnet $CIDR )
if [ -z "$PROJECT_SUBNET_ID" ]; then
  quantum subnet-create --tenant-id ${PROJECT_ID} \
                        --name ${PROJECT_SUBNET_NAME} \
                        ${PROJECT_NET_NAME} \
                        $CIDR
  PROJECT_SUBNET_ID=$( get_q_id subnet $CIDR )
fi  
  
# Create a router for the new tenant:

PROJECT_ROUTER_ID=$( get_q_id router ${PROJECT_ROUTER_NAME} )
if [ -z "$PROJECT_ROUTER_ID" ]; then
  quantum router-create --tenant-id  ${PROJECT_ID} ${PROJECT_ROUTER_NAME}
  PROJECT_ROUTER_ID=$( get_q_id router ${PROJECT_ROUTER_NAME} )
fi

# Add the router to the running l3 agent:

L3_AGENT_ID=$( quantum agent-list | grep "L3 agent" | awk '{print $2}' )

quantum l3-agent-router-add ${L3_AGENT_ID}  ${PROJECT_ROUTER_NAME}

# Add the router to the subnet:
quantum router-interface-add ${PROJECT_ROUTER_ID} ${PROJECT_SUBNET_ID}



#------------------------------
# Setup some security groups
# -----------------------------

quantum security-group-create  --tenant-id ${PROJECT_ID}  test-webservers --description "security group for webservers"
SEC_GROUP_ID=$( quantum security-group-list | grep test-webservers | awk '{print $2}' )

# Creating security group rule to allow web access
quantum security-group-rule-create --tenant-id ${PROJECT_ID} --direction ingress --protocol icmp --port_range_min -1 --port_range_max -1  --remote-ip-prefix 0.0.0.0/0 ${SEC_GROUP_ID}
quantum security-group-rule-create --tenant-id ${PROJECT_ID} --direction ingress --protocol tcp --port_range_min 22  --port_range_max 22  --remote-ip-prefix 0.0.0.0/0 ${SEC_GROUP_ID}
quantum security-group-rule-create --tenant-id ${PROJECT_ID} --direction ingress --protocol tcp --port_range_min 80  --port_range_max 80  --remote-ip-prefix 0.0.0.0/0 ${SEC_GROUP_ID}
quantum security-group-rule-create --tenant-id ${PROJECT_ID} --direction ingress --protocol tcp --port_range_min 443 --port_range_max 443 --remote-ip-prefix 0.0.0.0/0 ${SEC_GROUP_ID}
