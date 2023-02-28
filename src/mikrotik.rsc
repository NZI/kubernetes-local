/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/ip pool
add name=dhcp_pool0 ranges=192.168.99.2-192.168.99.254
/ip dhcp-server
add address-pool=dhcp_pool0 disabled=no interface=ether2 name=dhcp1
/ip address
add address=192.168.99.1/24 interface=ether2 network=192.168.99.0
/ip dhcp-server network
add address=192.168.99.0/24 gateway=192.168.99.1
/ip route
add distance=1 dst-address=192.168.99.0/24 gateway=10.0.2.2
/system identity
set name=RouterOS

###
### OSPF
###

# https://forum.mikrotik.com/viewtopic.php?t=166751

# --------
# ip address print 
# Flags: X - disabled, I - invalid, D - dynamic 
#  #   ADDRESS            NETWORK         INTERFACE                                                                                                                                                                          
#  0   10.10.0.1/20       10.10.0.0       lan-bridge                                                                                                                                                                         
#  1 D public-ip/24    public-ip     ether1  
 
# --------
# /ip route print
#  #      DST-ADDRESS        PREF-SRC        GATEWAY            DISTANCE
#  0 ADS  0.0.0.0/0                          public-ip               1
#  1 ADC  10.10.0.0/20       10.10.0.1       lan-bridge                0
#  2 ADb  10.10.2.1/32                       10.10.2.10               20
#  3 ADb  10.10.2.10/32                      10.10.2.10               20
#  4 ADb  10.10.2.100/32                     10.10.2.10               20
#  5 ADC  public-ip/24     public-ip    ether1                    0

# --------
# /routing bgp instance print 
# Flags: * - default, X - disabled 
#  0 *X name="default" as=60000 router-id=0.0.0.0 redistribute-connected=no redistribute-static=no redistribute-rip=no redistribute-ospf=no redistribute-other-bgp=no out-filter="" client-to-client-reflection=yes 
#       ignore-as-path-len=no routing-table="" 

#  1    name="k3s" as=400 router-id=10.10.0.1 redistribute-connected=no redistribute-static=no redistribute-rip=no redistribute-ospf=no redistribute-other-bgp=no out-filter="" client-to-client-reflection=yes 
#       ignore-as-path-len=no routing-table="" 

# --------
# /routing bgp peer print detail
# Flags: X - disabled, E - established 
#  0 E name="metallb" instance=k3s remote-address=10.10.2.10 remote-as=500 tcp-md5-key="" nexthop-choice=force-self multihop=no route-reflect=no hold-time=3m ttl=default in-filter="" out-filter="" address-families=ip 
#      default-originate=always remove-private-as=no as-override=no passive=no use-bfd=no 

# --------
# /routing bgp network print    
# Flags: X - disabled 
#  #   NETWORK              SYNCHRONIZE
#  0   10.10.2.0/24         yes        

# --------
# /routing bgp advertisements print 
# PEER     PREFIX               NEXTHOP          AS-PATH            ORIGIN     LOCAL-PREF
# metallb  0.0.0.0/0            10.10.0.1                            igp       

# --------
# metallb-bgp-config

# apiVersion: v1                                                                                                                                                                                                              
# kind: ConfigMap
# metadata:
#   namespace: metallb-system
#   name: config
# data:
#   config: |
#     peers:
#     - peer-address: 10.10.0.1
#       peer-asn: 400
#       my-asn: 500
#     address-pools:
#     - name: mikrotik
#       protocol: bgp
#       avoid-buggy-ips: true
#       addresses:
#       - 10.10.2.0/24
      
# --------
# metallb-l2-config

# apiVersion: v1                                                                                                                                                                                                              
# kind: ConfigMap
# metadata:
#   namespace: metallb-system
#   name: config
# data:
#   config: |
#     address-pools:
#     - name: mikrotik
#       protocol: layer2
#       avoid-buggy-ips: true
#       addresses:
#       - 10.10.2.0/24   