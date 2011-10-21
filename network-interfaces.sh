#!/bin/bash

brctl addbr br0
brctl addif br0 eth0
brctl addif br0 eth1

ifconfig eth0 0.0.0.0 up
ifconfig eth1 0.0.0.0 up
ifconfig br0 192.168.0.1 broadcast 192.168.0.255 netmask 255.255.255.0

