/interface bridge add name=lo0
/ip address add address=1.1.1.1/32 interface=lo0
/ip route add dst-address=10.9.0.0/16 gateway=lo0
