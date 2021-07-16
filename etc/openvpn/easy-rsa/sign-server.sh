#!/usr/bin/expect
spawn  ./easyrsa sign server server
expect "*Confirm request details:* "
send "yes\n"
expect "*Enter pass phrase* "
send "1234\n"
expect eof
exit
