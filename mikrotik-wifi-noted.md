/ip address add address=192.168.88.1/24 interface=ether5
/certificate add name=self-signed common-name=mikrotik-sign-self-signed
/certificate sign self-signed
/ip service enable www-ssl
/ip service set www-ssl certificate=self-signed

## Wifi
/interface wifi security add \
name=peet-sec \
authentication-types=wpa2-psk,wpa3-psk \
passphrase="XXXXXXX"

/interface wifi datapath add \
name=wifi-vlan40 \
bridge=bridge-lan \
vlan-id=40

/interface wifi configuration add \
name=peet-24 \
ssid="Peet 2.4G" \
country=Thailand \
security=peet-sec \
datapath=wifi-vlan40

/interface wifi configuration add \
name=peet-5 \
ssid="Peet 5G" \
country=Thailand \
security=peet-sec \
datapath=wifi-vlan40

/interface wifi set wifi1 configuration=peet-24 disabled=no
/interface wifi set wifi2 configuration=peet-5 disabled=no
