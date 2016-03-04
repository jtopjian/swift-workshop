cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/
cat > /root/.ssh/config <<EOF
Host *
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
EOF

_ip4=$(ip addr show dev eth0 | grep eth0 | tail -1 | awk '{print $2}' | cut -d/ -f1)

apt-get update
apt-get install ubuntu-cloud-keyring
add-apt-repository -y cloud-archive:liberty
apt-get update
apt-get install -y xfsprogs rsync
apt-get install -y memcached python-memcache

mkfs.xfs /dev/vdd
mkdir -p /srv/node/vdd

cat >> /etc/fstab <<EOF
/dev/vdd /srv/node/vdd xfs noatime,nodiratime,nobarrier,logbufs=0 0 2
EOF

mount /srv/node/vdd

cp /home/ubuntu/files/rsyncd.conf /etc
sed -i -e "s/{{ IP }}/$_ip4/g" /etc/rsyncd.conf
sed -i -e 's/RSYNC_ENABLE=false/RSYNC_ENABLE=true/g' /etc/default/rsync

apt-get install -y swift swift-account swift-container swift-object
cp /home/ubuntu/files/account-server.conf /etc/swift
cp /home/ubuntu/files/container-server.conf /etc/swift
cp /home/ubuntu/files/object-server.conf /etc/swift
cp /home/ubuntu/files/swift.conf /etc/swift
chown -R swift: /srv/node
chown -R swift: /etc/swift

/etc/init.d/rsync start
start swift-account-auditor
start swift-account
start swift-account-reaper
start swift-account-replicator
start swift-container-auditor
start swift-container
start swift-container-sync
start swift-container-updater
start swift-object-auditor
start swift-object
start swift-object-replicator
start swift-object-updater
