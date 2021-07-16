wget https://archives.fedoraproject.org/pub/archive/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -Uvh epel-release-6-8.noarch.rpm
yum install openvpn -y
yum install easy-rsa -y
yum install -y expect

mkdir -p /etc/openvpn/easy-rsa
cp -a /usr/share/easy-rsa/3/* /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa
echo 'set_var EASYRSA_REQ_COUNTRY     "CN"' >> vars
echo 'set_var EASYRSA_REQ_PROVINCE    "Henan"' >> vars
echo 'set_var EASYRSA_REQ_CITY        "Zhengzhou"' >> vars
echo 'set_var EASYRSA_REQ_ORG         "along"' >> vars
echo 'set_var EASYRSA_REQ_EMAIL       "along@163.com"' >> vars
echo 'set_var EASYRSA_REQ_OU          "My OpenVPN"' >> vars

#初始化pki
./easyrsa init-pki

#创建根证书
echo '#!/usr/bin/expect'>>build-ca.sh
echo 'spawn ./easyrsa build-ca'>>build-ca.sh
echo 'expect "Enter New CA Key Passphrase: "'>>build-ca.sh
echo 'send "1234\n"'>>build-ca.sh
echo 'expect "Re-Enter New CA Key Passphrase: "'>>build-ca.sh
echo 'send "1234\n"'>>build-ca.sh
echo 'expect "Common Name* "'>>build-ca.sh
echo 'send "along\n"'>>build-ca.sh
echo 'expect eof'>>build-ca.sh
echo 'exit'>>build-ca.sh
expect build-ca.sh

#创建服务器端证书
echo '#!/usr/bin/expect'>>gen-req-server.sh
echo 'spawn  ./easyrsa gen-req server nopass'>>gen-req-server.sh
echo 'expect "Common Name* "'>>gen-req-server.sh
echo 'send "along521\n"'>>gen-req-server.sh
echo 'expect eof'>>gen-req-server.sh
echo 'exit'>>gen-req-server.sh
expect gen-req-server.sh

#签约服务端证书
echo '#!/usr/bin/expect'>>sign-server.sh
echo 'spawn  ./easyrsa sign server server'>>sign-server.sh
echo 'expect "*Confirm request details:* "'>>sign-server.sh
echo 'send "yes\n"'>>sign-server.sh
echo 'expect "*Enter pass phrase* "'>>sign-server.sh
echo 'send "1234\n"'>>sign-server.sh
echo 'expect eof'>>sign-server.sh
echo 'exit'>>sign-server.sh
expect sign-server.sh

#创建Diffie-Hellman，确保key穿越不安全网络的命令
./easyrsa gen-dh


#创建客户端证书
echo '#!/usr/bin/expect'>>gen-req-client.sh
echo 'spawn  ./easyrsa gen-req client'>>gen-req-client.sh
echo 'expect "Enter PEM pass phrase* "'>>gen-req-client.sh
echo 'send "1234\n"'>>gen-req-client.sh
echo 'expect "Verifying* "'>>gen-req-client.sh
echo 'send "1234\n"'>>gen-req-client.sh
echo 'expect "Common Name* "'>>gen-req-client.sh
echo 'send "client\n"'>>gen-req-client.sh
echo 'expect eof'>>gen-req-client.sh
echo 'exit'>>gen-req-client.sh
expect gen-req-client.sh

#签约client
echo '#!/usr/bin/expect'>>sign-client.sh
echo 'spawn  ./easyrsa sign client client'>>sign-client.sh
echo 'expect "*Confirm request details:* "'>>sign-client.sh
echo 'send "yes\n"'>>sign-client.sh
echo 'expect "*Enter pass phrase* "'>>sign-client.sh
echo 'send "1234\n"'>>sign-client.sh
echo 'expect eof'>>sign-client.sh
echo 'exit'>>sign-client.sh
expect sign-client.sh

cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn/
cp /etc/openvpn/easy-rsa/pki/private/server.key /etc/openvpn/
cp /etc/openvpn/easy-rsa/pki/issued/server.crt /etc/openvpn/
cp /etc/openvpn/easy-rsa/pki/dh.pem /etc/openvpn/

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

#安装vim 
yum install -y vim 

#创建 配置文件 /etc/openvpn/server.conf
echo 'local 0.0.0.0     #监听地址'>>/etc/openvpn/server.conf
echo 'port 1194     #监听端口'>>/etc/openvpn/server.conf
echo 'proto tcp     #监听协议'>>/etc/openvpn/server.conf
echo 'dev tun     #采用路由隧道模式'>>/etc/openvpn/server.conf
echo 'ca /etc/openvpn/ca.crt      #ca证书路径'>>/etc/openvpn/server.conf
echo 'cert /etc/openvpn/server.crt       #服务器证书'>>/etc/openvpn/server.conf
echo 'key /etc/openvpn/server.key  # This file should be kept secret 服务器秘钥'>>/etc/openvpn/server.conf
echo 'dh /etc/openvpn/dh.pem     #密钥交换协议文件'>>/etc/openvpn/server.conf
echo 'server 10.8.0.0 255.255.255.0     #给客户端分配地址池，注意：不能和VPN服务器内网网段有相同'>>/etc/openvpn/server.conf
echo 'ifconfig-pool-persist ipp.txt'>>/etc/openvpn/server.conf
echo 'push "redirect-gateway def1 bypass-dhcp"      #给网关'>>/etc/openvpn/server.conf
echo 'push "dhcp-option DNS 8.8.8.8"        #dhcp分配dns'>>/etc/openvpn/server.conf
echo 'client-to-client       #客户端之间互相通信'>>/etc/openvpn/server.conf
echo 'keepalive 10 120       #存活时间，10秒ping一次,120 如未收到响应则视为断线'>>/etc/openvpn/server.conf
echo 'comp-lzo      #传输数据压缩'>>/etc/openvpn/server.conf
echo 'max-clients 100     #最多允许 100 客户端连接'>>/etc/openvpn/server.conf
echo 'user openvpn       #用户'>>/etc/openvpn/server.conf
echo 'group openvpn      #用户组'>>/etc/openvpn/server.conf
echo 'persist-key'>>/etc/openvpn/server.conf
echo 'persist-tun'>>/etc/openvpn/server.conf
echo 'status /var/log/openvpn/openvpn-status.log'>>/etc/openvpn/server.conf
echo 'log         /var/log/openvpn/openvpn.log'>>/etc/openvpn/server.conf
echo 'verb 3'>>/etc/openvpn/server.conf
echo 'duplicate-cn   #允许多用户使用同一个证书'>>/etc/openvpn/server.conf

#设置开机自启
systemctl -f enable openvpn@server.service

#开启openvpn 服务
systemctl start openvpn@server.service

#复制client证书
cp /etc/openvpn/easy-rsa/pki/issued/client.crt /etc/openvpn/client


