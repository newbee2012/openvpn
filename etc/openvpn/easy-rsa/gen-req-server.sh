#!/usr/bin/expect
spawn  ./easyrsa gen-req server nopass
expect "Common Name* "
send "along521\n"
expect eof
exit
