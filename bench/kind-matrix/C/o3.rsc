/interface bridge add name=lo0
/ip address add address=3.3.3.3/32 interface=lo0
/routing ospf instance add name=default router-id=3.3.3.3
/routing ospf area add name=backbone area-id=0.0.0.0 instance=default
/routing ospf interface-template add area=backbone interfaces=lo0 passive
/ip address add address=10.1.23.2/30 interface=ether13
/routing ospf interface-template add area=backbone interfaces=ether13 type=ptp
