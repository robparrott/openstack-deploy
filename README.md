openstack-deploy
================

Set of ansible playbooks for doing deployment 
studies of OpenStack and Releated technologuies 
in EC2, locally in Vagrant, or on hardware.

The goal will be to have a full ansible-based install in EC2 on multiple hosts,
that can then be adapted to use with physical hosts quickly.

Requirements
============

You need ansible from 

* https://github.com/ansible/ansible

The current version, or version >= 1.1.

To run in EC2 or vagrant, you'll need the prereqs for those tools as well.

Playbooks
=========

Packstack
---------

This playbook uses RDO and the packstack utility to build an all-in-one OpenStack 
instance, typically in EC2. It then converts then instance from using nova-network
to using quantum, and sets up a demo environment. For info on RDO, see

* http://openstack.redhat.com

Modify the vars file in packsrtack.vars.yaml, then invoke the playbook via

    $ ansible-playbook -v -i ansible_hosts rdo-packstack.yaml


Devstack
--------
This playbook will fire up an EC2 instance, attach a volume, and then deploy 
a full OpenStack instance on it, with all the bells and whistles including
heat and ceilometer.

This uses the development scripts from the devstack team:

* http://devstack.org

Invoke the playbook via

    $ ansible-playbook -v -i ansible_hosts devstack.yaml

Note: the ansible_hosts file just includes localhost, since the inventory is 
built dynamically based on queries with EC2.

To edit various single values of the deployment, such as passwords, volume size,
and the version of the OpenStack components to install, refer to the file at
./devstack/var/devstack_vars.yaml

To swap in the IaaS or host setup to use, modify the first "play" in the devstack.yaml playbook accordingly.

Gluster
-------
This playbook installs a gluster cluster in EC2 based on the Fedora Gluster UFO stack, with a 
Swift object storage front end.
