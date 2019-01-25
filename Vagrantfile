# -*- mode: ruby -*-
# vi: set ft=ruby :

ceph_repo = '../ceph'
ceph_iscsi_repo = '../ceph-iscsi'

settings = YAML.load_file('settings.yml')

nfs_auto_export = settings.has_key?('nfs_auto_export') ?
                  settings['nfs_auto_export'] : true

install_iscsi = settings.has_key?('install_iscsi') ?
                settings['install_iscsi'] : true

install_nfs = settings.has_key?('install_nfs') ?
              settings['install_nfs'] : true


Vagrant.configure("2") do |config|
  config.ssh.insert_key = false
  config.vm.box = "opensuse-leap-15.1"

  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.provision "file", source: "bin/", destination: "/home/vagrant/"

  config.vm.provider "libvirt" do |lv, override|
    if settings.has_key?('libvirt_host') then
      lv.host = settings['libvirt_host']
    end
    if settings.has_key?('libvirt_user') then
      lv.username = settings['libvirt_user']
    end
    if settings.has_key?('libvirt_use_ssl') then
      lv.connect_via_ssh = true
    end

    lv.memory = settings.has_key?('vm_memory') ? settings['vm_memory'] : 4096
    lv.cpus = settings.has_key?('vm_cpus') ? settings['vm_cpus'] : 2
    if settings.has_key?('vm_storage_pool') then
      lv.storage_pool_name = settings['vm_storage_pool']
    end
    lv.nic_model_type = "e1000"

    override.vm.synced_folder ceph_repo, '/home/vagrant/ceph', type: 'nfs',
                          :nfs_export => nfs_auto_export,
                          :mount_options => ['nolock,vers=3,udp,noatime,actimeo=1'],
                          :linux__nfs_options => ['rw','no_subtree_check','all_squash','insecure']

    override.vm.synced_folder ceph_iscsi_repo, '/home/vagrant/ceph-iscsi', type: 'nfs',
                          :nfs_export => nfs_auto_export,
                          :mount_options => ['nolock,vers=3,udp,noatime,actimeo=1'],
                          :linux__nfs_options => ['rw','no_subtree_check','all_squash','insecure']
  end

  config.vm.provider "virtualbox" do |lv, override|
    override.vm.synced_folder ceph_repo, "/home/vagrant/ceph"
    override.vm.synced_folder ceph_iscsi_repo, "/home/vagrant/ceph-iscsi"
  end
  config.vm.provision "shell", inline: <<-SHELL
    zypper ar https://download.opensuse.org/distribution/leap/15.1/repo/oss/ leap15.1
    zypper ar https://download.opensuse.org/repositories/filesystems:/ceph/openSUSE_Leap_15.0/filesystems:ceph.repo
    zypper ar https://download.opensuse.org/repositories/home:/dmdiss:/tcmu-runner-1.3/openSUSE_Leap_15.0/home:dmdiss:tcmu-runner-1.3.repo
    zypper --gpg-auto-import-keys ref

    # Install ceph
    zypper -n install ceph-base ceph-mon vim git

    # Configure ceph
    # TODO use ceph-iscsi-setup.sh
    if [ ! -e /home/vagrant/ceph/build/ceph.conf ]; then
      echo "No ceph cluster is running"
      exit 1
    fi
    mkdir -p /etc/ceph
    MON_ADDRS=`cat /home/vagrant/ceph/build/ceph.conf \
              | grep 'mon host' \
              | sed -e 's/.*mon host =  //' \
              | sed -e 's/] /]\\n/g' \
              | sed -e 's/.*v2:\\([0-9\.]\\+:[0-9]\\+\\),.*/\\1/g' \
              | sed -e ':a;N;$!ba;s/\\n/,/g'`

    echo "MON_ADDRS=$MON_ADDRS"
    # MON_ADDRS=`cat /home/vagrant/ceph/build/ceph.conf | grep 'mon addrs' | sed -e 's/.*mon addrs = //'`
    # MON_ADDRS=`echo $MON_ADDRS | sed 's/ /, /g'`
    echo "[client]" > /etc/ceph/ceph.conf
    echo "  mon host = $MON_ADDRS" >> /etc/ceph/ceph.conf
    echo "  keyring = /etc/ceph/ceph.client.admin.keyring" >> /etc/ceph/ceph.conf
    sudo cp /home/vagrant/ceph/build/keyring /etc/ceph/ceph.client.admin.keyring

    if #{install_iscsi}; then
      /home/vagrant/bin/ceph-iscsi-provision.sh
    fi

    if #{install_nfs}; then
      /home/vagrant/ceph-nfs-provision.sh
    fi

  SHELL

  config.vm.define :node1 do |node1|
    node1.vm.hostname = "node1.ceph.local"
    node1.vm.network :private_network, ip: "192.168.100.201"
    node1.vm.provision "shell", inline: <<-SHELL
      hostnamectl set-hostname node1.ceph.local
      if ! grep -q '^192.168.100.202 node2$' /etc/hosts; then
        echo "192.168.100.202 node2" >> /etc/hosts
      fi
      if ! grep -q '^192.168.100.203 node3$' /etc/hosts; then
        echo "192.168.100.203 node3" >> /etc/hosts
      fi
    SHELL
  end

  config.vm.define :node2 do |node2|
    node2.vm.hostname = "node2.ceph.local"
    node2.vm.network :private_network, ip: "192.168.100.202"
    node2.vm.provision "shell", inline: <<-SHELL
      hostnamectl set-hostname node2.ceph.local
      if ! grep -q '^192.168.100.201 node1$' /etc/hosts; then
        echo "192.168.100.201 node1" >> /etc/hosts
      fi
      if ! grep -q '^192.168.100.203 node3$' /etc/hosts; then
        echo "192.168.100.203 node3" >> /etc/hosts
      fi
    SHELL
  end

  config.vm.define :node3 do |node3|
    node3.vm.hostname = "node3.ceph.local"
    node3.vm.network :private_network, ip: "192.168.100.203"
    node3.vm.provision "shell", inline: <<-SHELL
      hostnamectl set-hostname node3.ceph.local
      if ! grep -q '^192.168.100.201 node1$' /etc/hosts; then
        echo "192.168.100.201 node1" >> /etc/hosts
      fi
      if ! grep -q '^192.168.100.202 node2$' /etc/hosts; then
        echo "192.168.100.202 node2" >> /etc/hosts
      fi
    SHELL
  end

end
