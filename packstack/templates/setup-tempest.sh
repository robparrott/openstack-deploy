#!/bin/bash

#
# Create a tempest.conf file
#
TEMPEST_DIR=/tmp/tempest
TEMPEST_CONF=${TEMPEST_DIR}/etc/tempest.conf

cd ${TEMPEST_DIR}
cp ${TEMPEST_DIR}/etc/tempest.conf.sample ${TEMPEST_CONF}

#
# Select an image
#
IMAGE_ID=$(  glance index | grep cirros  | grep qcow2 | awk '{ print $1 }' )
IMAGE_ID2=$( glance index | grep quantal | grep qcow2 | awk '{ print $1 }' )
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

