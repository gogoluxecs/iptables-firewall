#!/bin/sh

#
# Basic configuration rules
#
ipt="/sbin/iptables"
ext="eth2"

#
# Reset firwall rules
#
$ipt -F
$ipt -F INPUT
$ipt -F OUTPUT
$ipt -F FORWARD
$ipt -F -t mangle
$ipt -F -t nat
$ipt -X

#
# Setup firwall
#
$ipt -P INPUT DROP
$ipt -P OUTPUT ACCEPT
$ipt -P FORWARD ACCEPT

echo 1 > /proc/sys/net/ipv4/ip_forward
$ipt -t nat -A POSTROUTING -o $ext -j MASQUERADE

$ipt -A FORWARD -p tcp -i $ext -d 192.168.0.10 --dport 29656 -j ACCEPT
$ipt -A FORWARD -i $ext -m state --state NEW,INVALID -j DROP

#
# Place to setup forwarding or block forwarding rules
#
$ipt -t nat -A PREROUTING -i $ext -p tcp --dport 29656 -j DNAT --to 192.168.0.10:29656

#
# Firewall chain
#
$ipt -N firewall
$ipt -A firewall -m limit --limit 15/minute -j LOG --log-prefix Firewall:
$ipt -A firewall -j DROP

$ipt -N dropwall
$ipt -A dropwall -m limit --limit 15/minute -j LOG --log-prefix Dropwall:
$ipt -A dropwall -j DROP

$ipt -N badflags
$ipt -A badflags -m limit --limit 15/minute -j LOG --log-prefix Badflags:
$ipt -A badflags -j DROP

$ipt -N silent
$ipt -A silent -j DROP

#
# Local machines
#
$ipt -A INPUT -i lo -j ACCEPT
$ipt -A INPUT -i br0 -j ACCEPT

#
# Bad flag combinations
#
$ipt -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j badflags
$ipt -A INPUT -p tcp --tcp-flags ALL ALL -j badflags
$ipt -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j badflags
$ipt -A INPUT -p tcp --tcp-flags ALL NONE -j badflags
$ipt -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j badflags
$ipt -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j badflags

$ipt -A INPUT -p icmp --icmp-type 0 -j ACCEPT
$ipt -A INPUT -p icmp --icmp-type 3 -j ACCEPT
$ipt -A INPUT -p icmp --icmp-type 11 -j ACCEPT
$ipt -A INPUT -p icmp --icmp-type 8 -m limit --limit 1/second -j ACCEPT
$ipt -A INPUT -p icmp -j firewall

#
# Services
#
$ipt -A INPUT -i $ext -s 0/0 -d 0/0 -p tcp --dport 80 -j ACCEPT
$ipt -A INPUT -i $ext -p tcp --dport 29656 -j ACCEPT

#$ipt -t nat -A PREROUTING -i $ext -p tcp --dport 29656 -j DNAT --to 192.168.0.10:29656
#$ipt -A FORWARD -p tcp -i $ext -d 192.168.0.10 --dport 29656 -j ACCEPT

$ipt -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
$ipt -A INPUT -p udp --sport 137 --dport 137 -j silent
$ipt -A INPUT -j dropwall
