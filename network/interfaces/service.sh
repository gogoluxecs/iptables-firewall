#!/bin/bash
PATH="/sbin:/usr/sbin:/usr/local/sbin";
slaveIfs="1 2 3 4 6 7 8 9 10";
cmd="$1";
[ -z "$cmd" ] && cmd="start";
case "$cmd" in
  start)
    brctl addbr br0;
    brctl stp br0 on;
    brctl addif br0 eth0;
    brctl addif br0 eth1;
    (ifdown eth0 1>/dev/null 2>&1;);
    (ifdown eth1 1>/dev/null 2>&1;);
    ifconfig eth0 0.0.0.0 up;
    ifconfig eth1 0.0.0.0 up;
    ifconfig br0 10.0.3.129 broadcast 10.0.3.255 netmask 255.255.255.0 up ### Adapt to your needs.
    
	route add default gw 10.0.3.129; ### Adapt to your needs.
    for file in br0 eth0 eth1;
    do
      echo "1" > /proc/sys/net/ipv4/conf/${file}/proxy_arp;
      echo "1" > /proc/sys/net/ipv4/conf/${file}/forwarding;
    done;
    echo "1" > /proc/sys/net/ipv4/ip_forward;
    ;;
  stop)
    brctl delif br0 eth0;
    brctl delif br0 eth1;
    ifconfig br0 down;
    brctl delbr br0;
    #ifup eth0; ### Adapt to your needs.
    #ifup eth1; ### Adapt to your needs.
    ;;
  restart,reload)
    $0 stop;
    sleep 3;
    $0 start;
    ;;
esac;
