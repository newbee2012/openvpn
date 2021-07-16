#!/usr/bin/expect
spawn ./easyrsa build-ca
expect "Enter New CA Key Passphrase: "
send "1234\n"
expect "Re-Enter New CA Key Passphrase: "
send "1234\n"
expect "Common Name* "
send "along\n"
expect eof
exit
