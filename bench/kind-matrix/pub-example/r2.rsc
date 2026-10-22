/ip address add address=10.0.0.2/30 interface=ether2
/ip route add dst-address=0.0.0.0/0 gateway=10.0.0.1
/interface bridge add name=lo0
/ip address add address=2.2.2.2/32 interface=lo0
