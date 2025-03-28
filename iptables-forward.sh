#!/bin/bash

### Parse arguments
for arg in "$@"; do
    case $arg in
        --action=*)
            ACTION="${arg#*=}"
            shift
            ;;
        --interface=*)
            HOST_INTERFACE="${arg#*=}"
            shift
            ;;
        --container-ip=*)
            CONTAINER_IP="${arg#*=}"
            shift
            ;;
        *)
            echo "Unknown parameter: $arg"
            exit 1
            ;;
    esac
done


### Default values
: "${HOST_INTERFACE:=enp1s0}"
: "${CONTAINER_IP:=172.35.0.2/32}"


### Validate action
if [[ -z "$ACTION" ]]; then
    echo "Missing --action parameter (must be 'enable' or 'disable')"
    exit 1
fi
if [[ "$ACTION" != "enable" && "$ACTION" != "disable" ]]; then
    echo "Invalid action: $ACTION (must be 'enable' or 'disable')"
    exit 1
fi


### Determine iptables command
if [[ "$ACTION" == "enable" ]]; then
    echo "Enable IP forward"
    IPT_CMD="-A"
elif [[ "$ACTION" == "disable" ]]; then
    echo "Disable IP forward"
    IPT_CMD="-D"
fi
echo "Host interface: ${HOST_INTERFACE} - Container IP address: ${CONTAINER_IP}"


### Apply iptables rules
### NAT rule: allow outgoing traffic from the container through the host interface
iptables -t nat $IPT_CMD POSTROUTING -s "$CONTAINER_IP" -o "$HOST_INTERFACE" -j MASQUERADE
### Forward rule: allow forwarding container traffic to outside
iptables $IPT_CMD FORWARD -s "$CONTAINER_IP" -o "$HOST_INTERFACE" -j ACCEPT
### Forward return rule: allow incoming related traffic back to container
iptables $IPT_CMD FORWARD -d "$CONTAINER_IP" -i "$HOST_INTERFACE" -m state --state RELATED,ESTABLISHED -j ACCEPT


### Enable IP forwarding if action is enable
if [[ "$ACTION" == "enable" ]]; then
    sysctl -w net.ipv4.ip_forward=1 > /dev/null
fi


### Status output
echo "iptables rules ${ACTION}d for $CONTAINER_IP via $HOST_INTERFACE"
echo "Current IP forwarding setting:"
cat /proc/sys/net/ipv4/ip_forward
