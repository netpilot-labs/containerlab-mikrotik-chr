/ip address add address=172.16.0.2/30 interface=ether2
/interface bridge add name=lo0
/interface ethernet set ether2 network-type=point-to-point
/ip address add address=4.4.4.4/32 interface=lo0
