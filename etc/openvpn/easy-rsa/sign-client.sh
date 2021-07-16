#!/usr/bin/expect
spawn  ./easyrsa sign client client
expect "*Confirm request details:* "
send "yes\n"
expect "*Enter pass phrase* "
send "1234\n"
expect eof
exit
