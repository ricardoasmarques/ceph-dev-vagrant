# Requirements

- Ceph repo must exist in `../ceph` location
- Ceph `vstart` cluster must be running
- Read permissions on keyring
    -  `# chmod +r ../ceph/build/keyring`
- Libvirt
    - `# zypper install libvirt-devel libvirt-daemon`
    - `# systemctl enable libvirtd`
    - `# systemctl restart libvirtd`
- Vagrant
    - `# zypper in ruby-devel gcc make zlib-devel`
- Optionally, virtual machine manager can be useful
    - `# zypper in virt-manager`

# Setup

Get the `opensuse-leap-15.1` vagrant box:

    # Go to https://download.opensuse.org/repositories/home:/rjdias:/branches:/home:/jloehel:/vagrant:/images/images_leap_15_1/
    # Copy the <VAGRANT_BOX_URL> for the `.vagrant.libvirt.box` file
    wget <VAGRANT_BOX_URL>

Add the `opensuse-leap-15.1` box to vagrant:

    vagrant box add opensuse-leap-15.1 <VAGRANT_BOX_FILENAME>

Install the `vagrant-libvirt` plugin

    vagrant plugin install vagrant-libvirt

# Usage

## Start VMs

- `vagrant up --provider libvirt`

> If you experience an error while running vagrant up, try the following:
> \- `#zypper in libgcrypt-devel`
> \- `#systemctl stop vboxdrv`
> \- `#systemctl start nfs`
> \- `#SuSEfirewall2 off`

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
cd /iscsi-targets
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
cd /iscsi-targets/iqn.2003-01.com.redhat.iscsi-gw:iscsi-igw/hosts
create iqn.1994-05.com.redhat:rh7-client
auth username=myiscsiusername password=myiscsipassword
disk add rbd/disk_1
```

More information can be found at:
http://docs.ceph.com/docs/master/rbd/iscsi-overview/
