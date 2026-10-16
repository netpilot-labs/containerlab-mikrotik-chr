/interface bridge add name=lo0
/ip address add address=2.2.2.2/32 interface=lo0
/routing ospf instance add name=default router-id=2.2.2.2
/routing ospf area add name=backbone area-id=0.0.0.0 instance=default
/routing ospf interface-template add area=backbone interfaces=lo0 passive
/ip address add address=10.1.12.2/30 interface=ether2
/ip address add address=10.1.23.1/30 interface=ether3
/routing ospf interface-template add area=backbone interfaces=ether2,ether3 type=ptp
