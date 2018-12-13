# -*- mode: ruby -*-
# vi: set ft=ruby :

ceph_repo = '../ceph'
ceph_iscsi_repo = '../ceph-iscsi'

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "centos/7"
  #config.vm.box = "opensuse/openSUSE-Tumbleweed-x86_64"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder ceph_repo, "/home/vagrant/ceph"
  config.vm.synced_folder ceph_iscsi_repo, "/home/vagrant/ceph-iscsi"
  config.vm.synced_folder "./bin", "/home/vagrant/bin"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", inline: <<-SHELL
    cat > /etc/yum.repos.d/ceph.repo <<EOF
[ceph]
name=Ceph packages for x86_64
baseurl=https://download.ceph.com/rpm-mimic/el7/x86_64
enabled=1
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-noarch]
name=Ceph noarch packages
baseurl=https://download.ceph.com/rpm-mimic/el7/noarch
enabled=1
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-source]
name=Ceph source packages
baseurl=https://download.ceph.com/rpm-mimic/el7/SRPMS
enabled=0
priority=2
gpgcheck=1
gpgkey=https://download.ceph.com/keys/release.asc
EOF

    sudo rpm --import 'https://download.ceph.com/keys/release.asc'
    sudo yum -y update
    sudo yum -y install epel-release
    sudo yum -y install git
    sudo yum -y install python-setuptools
    sudo yum -y install pyOpenSSL

    # Install ceph
    sudo yum -y install ceph-base

    # Install targetcli
    cd /home/vagrant
    git clone https://github.com/open-iscsi/targetcli-fb.git
    cd targetcli-fb
    sudo python setup.py install

    # Install configshell
    cd /home/vagrant
    git clone https://github.com/open-iscsi/configshell-fb.git
    cd configshell-fb
    sudo python setup.py install

    #Install python-rtslib
    cd /home/vagrant
    git clone https://github.com/open-iscsi/rtslib-fb.git
    cd rtslib-fb
    sudo python setup.py install

    # Install tcmu-runner
    cd /home/vagrant
    git clone https://github.com/open-iscsi/tcmu-runner.git
    cd tcmu-runner
    ./extra/install_dep.sh
    cmake -Dwith-glfs=false -Dwith-qcow=false -DSUPPORT_SYSTEMD=ON -DCMAKE_INSTALL_PREFIX=/usr .
    make
    sudo make install
    sudo cp org.kernel.TCMUService1.service /usr/share/dbus-1/system-services
    sudo cp tcmu-runner.service /lib/systemd/system

    # Install ceph-iscsi
    cd /home/vagrant
    cd ceph-iscsi
    sudo python setup.py install
    sudo cp /home/vagrant/ceph-iscsi/usr/lib/systemd/system/rbd-target-gw.service /usr/lib/systemd/system
    sudo cp /home/vagrant/ceph-iscsi/usr/lib/systemd/system/rbd-target-api.service /usr/lib/systemd/system
    sudo yum -y install python-netifaces python-flask python-netaddr python-cryptography

    # Configure ceph
    if [ ! -e /home/vagrant/ceph/build/ceph.conf ]; then
      echo "No ceph cluster is running"
      exit 1
    fi
    mkdir -p /etc/ceph
    MON_ADDRS=`cat /home/vagrant/ceph/build/ceph.conf | grep 'mon addr' | sed -e 's/.*mon addr = //'`
    MON_ADDRS=`echo $MON_ADDRS | sed 's/ /, /g'`
    echo "[client]" > /etc/ceph/ceph.conf
    echo "  mon host = $MON_ADDRS" >> /etc/ceph/ceph.conf
    echo "  keyring = /etc/ceph/ceph.client.admin.keyring" >> /etc/ceph/ceph.conf
    sudo cp /home/vagrant/ceph/build/keyring /etc/ceph/ceph.client.admin.keyring

    cat > /etc/ceph/iscsi-gateway.cfg <<EOF
# http://docs.ceph.com/docs/master/rbd/iscsi-target-cli/
[config]
cluster_name = ceph
gateway_keyring = ceph.client.admin.keyring
api_secure = false
api_user = admin
api_password = admin
api_port = 5001
trusted_ip_list = 192.168.100.201,192.168.100.202,192.168.100.203
EOF

    if ! rados lspools | grep -q '^rbd$'; then
      ceph osd pool create rbd 1 1
      rbd pool init rbd
    fi

    # Start services
    sudo systemctl daemon-reload
    # tcmu-runner
    sudo systemctl enable tcmu-runner
    sudo systemctl restart tcmu-runner
    # ceph-iscsi-config
    sudo systemctl enable rbd-target-gw
    sudo systemctl restart rbd-target-gw
    # ceph-iscsi-cli
    sudo systemctl enable rbd-target-api
    sudo systemctl restart rbd-target-api
  SHELL

  config.vm.define :node1 do |node1|
    node1.vm.hostname = "node1.ceph.local"
    node1.vm.network :private_network, ip: "192.168.100.201"
    node1.vm.provision "shell", inline: <<-SHELL
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
      if ! grep -q '^192.168.100.201 node1$' /etc/hosts; then
        echo "192.168.100.201 node1" >> /etc/hosts
      fi
      if ! grep -q '^192.168.100.202 node2$' /etc/hosts; then
        echo "192.168.100.202 node2" >> /etc/hosts
      fi
    SHELL
  end

end
