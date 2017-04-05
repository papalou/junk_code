#!/bin/sh

echo "Config iptables rules"

#Flush all Tables and rules
iptables --table nat --flush
iptables --flush

#Set all policy
iptables --policy INPUT DROP
iptables --policy OUTPUT DROP
iptables --policy FORWARD DROP

#Accept input/output port 80
iptables --append INPUT --in-interface eth0 --protocol tcp --destination-port 80 --jump ACCEPT
iptables --append OUTPUT --out-interface eth0 --protocol tcp --source-port 80 --jump ACCEPT

#Accept input/output port 443
iptables --append INPUT --in-interface eth0 --protocol tcp --destination-port 443 --jump ACCEPT
iptables --append OUTPUT --out-interface eth0 --protocol tcp --source-port 443 --jump ACCEPT

#Accept input/output port 80 from nextcloud lxc container or the web
iptables --append INPUT --in-interface eth0 --protocol tcp --source-port 80 --jump ACCEPT
iptables --append OUTPUT --out-interface eth0 --protocol tcp --destination-port 80 --jump ACCEPT

#Accept input/ouput dns resolv
iptables --append INPUT --in-interface eth0 --protocol udp --source-port 53 --jump ACCEPT
iptables --append OUTPUT --out-interface eth0 --protocol udp --destination-port 53 --jump ACCEPT

#Accept input/output port 443 from nextcloud lxc container or the web
iptables --append INPUT --in-interface eth0 --protocol tcp --source-port 443 --jump ACCEPT
iptables --append OUTPUT --out-interface eth0 --protocol tcp --destination-port 443 --jump ACCEPT


echo "config done"
