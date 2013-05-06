#!/bin/bash


function get_id 
{
   RETVAL=$( keystone ${1}-list | grep ${2} | awk '{print $2}' )
   echo $RETVAL
}

source /root/keystonerc_admin
                
#
# Create a quantum service
#
Q_SERVICE_ID=$( get_id service quantum )
if [ -z "$Q_SERVICE_ID" ]; then
   keystone service-create --name=quantum --type=network --description="Quantum Service"
   Q_SERVICE_ID=$( get_id service quantum )
fi

# Create an endpoint for quantum

Q_ENDPOINT_ID=$( get_id endpoint ":9696" )
if [ -z "$Q_ENDPOINT_ID" ]; then
   keystone endpoint-create --region RegionOne \
                            --service-id $Q_SERVICE_ID  \
                            --publicurl "http://127.0.0.1:9696" \
                            --adminurl "http://127.0.0.1:9696" \
                            --internalurl "http://127.0.0.1:9696"
   Q_ENDPOINT_ID=$( get_id endpoint ":9696" )
fi   
   
# Create a user for the quantum service

SERVICES_ID=$( get_id tenant services )
Q_USER_ID=$(   get_id user quantum )
if [ -z "$Q_USER_ID" ]; then
  keystone user-create --name quantum --email quantum@example.com --pass quantum --tenant-id ${SERVICES_ID}
  Q_USER_ID=$(   get_id user quantum )
fi
  
# Add the quantum user to the admin role (or fail gracefully...)

ADMIN_ROLE_ID=$(   get_id role admin )
keystone user-role-add --user_id ${Q_USER_ID} --role_id ${ADMIN_ROLE_ID} --tenant_id ${SERVICES_ID} || /bin/true
