#!/bin/bash

TUN_DEV="tun4"
TUN_GATEWAY="10.0.0.1"
TUN_ADDR="10.0.0.2"
TUN_NETMASK="255.255.255.0"
GATEWAY="$(ip route | grep -v tun | awk '/default/ { print $3 }')"
SERVER_ADDR="103.57.189.30"
DNS_1="8.8.8.8"
DNS_2="8.8.4.4"
SOCKS_PORT="10808"
DEFAULT_ROUTE="$(ip route show | grep default)"
ROUTE_LOG="route.log"

function init_tun_dev {
    ip tuntap add dev ${TUN_DEV} mode tun
    echo -e "Tund device started!"
}

function destroy_tun_dev {
    ifconfig ${TUN_DEV} down
    ip tuntap del dev ${TUN_DEV} mode tun
    echo -e "Tun device removed!"
}

function start_tun2socks {
    # Set ip address for tun interface
    ifconfig ${TUN_DEV} ${TUN_GATEWAY} netmask ${TUN_NETMASK}

    # Start tun2socks
    tun2socks -tunName ${TUN_DEV} -tunAddr ${TUN_ADDR} -proxyType socks -proxyServer 127.0.0.1:${SOCKS_PORT} -loglevel none

    # Backup default route to log file and remove default route
    echo ${DEFAULT_ROUTE} > ${ROUTE_LOG} \
        && ip route del ${DEFAULT_ROUTE}

    # Add default route to tun2socks
    route add default gw ${TUN_ADDR} metric 6
    echo -e "Tun2socks started!"
}

function stop_tun2socks {
    # Kill tun2socks program
    kill $(ps -aux | grep tun2socks | awk {'print $2'})

    # Recover default route
    ip route add $(cat "${ROUTE_LOG}") \
        && rm -rf "${ROUTE_LOG}"

    # Remove default route to tun2socks
    route del default gw ${TUN_ADDR} metric 6
    echo -e "Tun2socks stopped!"
}

function route_add_ip {
    # Add manual route to original gateway
    route add ${SERVER_ADDR} gw ${GATEWAY} metric 4
    route add ${DNS_1} gw ${GATEWAY} metric 4
    route add ${DNS_2} gw ${GATEWAY} metric 4
    echo -e "Routes added"
}

function route_del_ip {

}