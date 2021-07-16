#!/usr/bin/expect
spawn  ./easyrsa gen-req client
expect "Enter PEM pass phrase* "
send "1234\n"
expect "Verifying* "
send "1234\n"
expect "Common Name* "
send "client\n"
expect eof
exit
