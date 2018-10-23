# Requirements

- Ceph repo must exist in `../ceph` location
- Ceph `vstart` cluster must be running
- Read permission on  `../ceph/build/keyring`
  (e.g., `sudo chmod +r ../ceph/build/keyring`)

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

[http://docs.ceph.com/docs/master/rbd/iscsi-overview/]()
