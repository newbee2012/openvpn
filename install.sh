#!/bin/sh
wget https://archives.fedoraproject.org/pub/archive/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -Uvh epel-release-6-8.noarch.rpm
yum install openvpn -y
yum install easy-rsa -y
yum install git -y

git clone https://github.com/newbee2012/openvpn.git
cp -rf ./openvpn/etc/openvpn/* /etc/openvpn

mkdir /var/log/openvpn
chown -R openvpn.openvpn /var/log/openvpn/
chown -R openvpn.openvpn /etc/openvpn/*

#iptables 设置nat 规则和打开路由转发 
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j MASQUERADE
#查看iptables规则
iptables -vnL -t nat
#iptables规则加入开机启动
echo "iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j MASQUERADE" >> /etc/rc.d/rc.local

sed 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g'  /etc/sysctl.conf > sysctl.conf.tmp
cat sysctl.conf.tmp > /etc/sysctl.conf
sysctl -p

#设置开机自启
systemctl -f enable openvpn@server.service

#开启openvpn 服务
systemctl start openvpn@server.service

