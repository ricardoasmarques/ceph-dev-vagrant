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

http://docs.ceph.com/docs/master/rbd/iscsi-overview/

# Troubleshooting

## There was on error while executing VBoxManage

Full error:
```bash
There was on error while executing VBoxManage, a CLI used by Vagrant for
controlling VirtualBox. The command and stderr is shown below Command:
["hostonlyif", "create"]

Stderr: 0%... Progress state: NS_ERROR_FAILURE VBoxManage: error: Failed to
create the host-only adapter VBoxManage: error: VBoxNetAdpCtl: Error while
adding new interface: failed to open /dev/vboxnetctl: No such file or directory

VBoxManage: error: Details: code NS_ERROR_FAILURE (0x80004005), component
HostNetworkInterface, interface IHostNetworkInterface VBoxManage: error:
Context: "int handleCreate(HandlerArg*, int, int*)" at line 68 of file
VBoxManageHostonly.cpp
```

Solution:

```bash
  sudo modprobe vboxdrv
  sudo modprobe vboxnetadp
  sudo modprobe vboxnetflt
```