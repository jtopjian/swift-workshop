cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/
cp /home/ubuntu/.ssh/id_rsa /root/.ssh
chmod 0600 /home/ubuntu/.ssh/id_rsa
chmod 0600 /root/.ssh/id_rsa

cat > /root/.ssh/config <<EOF
Host *
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
EOF


cat > /etc/network/interfaces.d/eth1.cfg <<EOF
auto eth1
iface eth1 inet static
  address 192.168.1.10
  netmask 255.255.255.0
EOF

ifup eth1
_ip4=$(ip addr show dev eth1 | grep eth1 | tail -1 | awk '{print $2}' | cut -d/ -f1)

echo 1 > /proc/sys/net/ipv4/ip_forward
/sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
/sbin/iptables -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
/sbin/iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT

apt-get update
apt-get install ubuntu-cloud-keyring
add-apt-repository -y cloud-archive:liberty
apt-get update
apt-get install -y keystone python-openstackclient
apt-get install -y swift swift-proxy python-swiftclient
apt-get install -y memcached python-memcache

cp /home/ubuntu/files/keystone.conf /etc/keystone
chown -R keystone: /etc/keystone
chown -R keystone: /var/lib/keystone
touch /var/log/keystone/keystone.log
chown -R keystone: /var/log/keystone

restart keystone
sleep 5

cat > /root/openrc <<EOF
export OS_AUTH_URL=http://$_ip4:5000/v2.0
export OS_TENANT_NAME="admin"
export OS_USERNAME="admin"
export OS_PASSWORD=password
EOF

export OS_TOKEN="password"
export OS_URL="http://localhost:35357/v3"
export OS_IDENTITY_API_VERSION=3

openstack service create --name keystone identity
openstack endpoint create --region RegionOne identity public http://${_ip4}:5000/v2.0
openstack endpoint create --region RegionOne identity internal http://${_ip4}:5000/v2.0
openstack endpoint create --region RegionOne identity admin http://${_ip4}:35357/v2.0

openstack service create --name swift object-store
_swift_id=$(openstack service list | grep swift | awk '{print $2}')
openstack endpoint create --region RegionOne $_swift_id public http://${_ip4}:8080/v1/AUTH_%\(tenant_id\)s
openstack endpoint create --region RegionOne $_swift_id internal http://${_ip4}:8080/v1/AUTH_%\(tenant_id\)s
openstack endpoint create --region RegionOne $_swift_id admin http://${_ip4}:8080/v1

openstack role create admin

openstack project create --domain default --description "Admin Project" admin
openstack project create --domain default --description "Services Project" service
openstack project create --domain default --description "Demo Project" demo

openstack user create --domain default --password password admin
openstack role add --project admin --user admin admin
openstack user create --domain default --password password swift
openstack role add --project service --user swift admin
openstack user create --domain default --password password demo
openstack role add --project demo --user demo _member_

mkdir /etc/swift
cp /home/ubuntu/files/create_rings.sh /etc/swift
pushd /etc/swift
bash create_rings.sh
popd

cp /home/ubuntu/files/swift.conf /etc/swift
cp /home/ubuntu/files/proxy-server.conf /etc/swift
sed -i -e "s/{{ IP }}/$_ip4/g" /etc/swift/proxy-server.conf
start swift-proxy
