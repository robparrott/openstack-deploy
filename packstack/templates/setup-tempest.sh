#!/bin/bash

#
# Create a tempest.conf file
#
TEMPEST_DIR=/tmp/openstack/tempest
TEMPEST_CONF=${TEMPEST_DIR}/etc/tempest.conf

cd ${TEMPEST_DIR}
cp ${TEMPEST_DIR}/etc/tempest.conf.sample ${TEMPEST_CONF}

#
# Select an image
#
IMAGE_ID=$(  glance index | grep cirros  | grep qcow2 | awk '{ print $1 }' )
IMAGE_ID2=$( glance index | grep quantal | grep qcow2 | awk '{ print $1 }' )

#
# Select a public network
#
PUBLIC_NETWORK_ID=$( echo NA )
PUBLIC_ROUTER_ID=$( echo NA )
#
# Configure it 
#

CONFIG="openstack-config --set ${TEMPEST_CONF} "

${CONFIG} identity uri               ${OS_AUTH_URL}

${CONFIG} identity username          test_user
${CONFIG} identity password          bananaDaiquiri
${CONFIG} identity tenant_name       test_project

${CONFIG} identity admin_username    admin
${CONFIG} identity admin_password    ${OS_PASSWORD}
${CONFIG} identity admin_tenant_name admin

${CONFIG} compute  image_ref         ${IMAGE_ID}
${CONFIG} compute  image_ref_alt     ${IMAGE_ID2} 
${CONFIG} compute  flavor_ref        1
${CONFIG} compute  flavor_ref_alt    2

${CONFIG} network  public_network_id ${PUBLIC_NETWORK_ID}
${CONFIG} network  public_router_id  ${PUBLIC_ROUTER_ID}
${CONFIG} network  quantum_available true


