# Requirements

- Ceph repo must exist in `../ceph` location
- Ceph `vstart` cluster must be running
- Read permission on  `../ceph/build/keyring`
  (e.g., `sudo chmod +r ../ceph/build/keyring`)
- `vagrant plugin install vagrant-vbguest`

# Usage

## Start VMs

- `vagrant up`

## Accessing VMs

- `vagrant ssh node1`

- `vagrant ssh node2`

## Connect to ceph cluster

Each time you restart your `vstart` ceph cluster, you have to
configure `/etc/ceph/ceph.conf` and `/etc/ceph/keyring` accordingly, or simply run:

- `vagrant provision`

## Configure iSCSI

To configure iSCSI you need to run the following commands:

```
# As root, on a iSCSI gateway node, start the iSCSI gateway command-line interface:
sudo gwcli
```

```
# Create iSCSI target and gateways
cd /iscsi-target
create iqn.2003-01.com.redhat.iscsi-gw:iscsi-igw
cd iqn.2003-01.com.redhat.iscsi-gw:iscsi-igw/gateways
create node1 192.168.100.201 skipchecks=true
create node2 192.168.100.202 skipchecks=true
```

Wait a bit, so the creation of gateways can finish.

```
# Add RBD image and disk
cd /disks
create pool=rbd image=disk_1 size=90G
cd /iscsi-target/iqn.2003-01.com.redhat.iscsi-gw:iscsi-igw/hosts
create iqn.1994-05.com.redhat:rh7-client
auth chap=myiscsiusername/myiscsipassword
disk add rbd.disk_1
```

More information can be found at:
http://docs.ceph.com/docs/master/rbd/iscsi-overview/
