if [ ! -e /home/vagrant/ceph/build/ceph.conf ]; then
      echo "ERROR: No ceph cluster is running"
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