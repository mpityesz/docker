#!/bin/bash

### Parse arguments
for arg in "$@"; do
    case $arg in
        --action=*)
            ACTION="${arg#*=}"
            shift
            ;;
        --ports=*)
            PORT_LIST="${arg#*=}"
            shift
            ;;
        *)
            echo "Unknown parameter: $arg"
            exit 1
            ;;
    esac
done


### Validate action
if [[ -z "$ACTION" ]]; then
    echo "Missing --action parameter (must be 'enable' or 'disable')"
    exit 1
fi
if [[ "$ACTION" != "enable" && "$ACTION" != "disable" ]]; then
    echo "Invalid action: $ACTION (must be 'enable' or 'disable')"
    exit 1
fi


### Default port list
: "${PORT_LIST:=51820/udp}"


### Validate port list
if [[ -z "$PORT_LIST" ]]; then
    echo "Missing --ports parameter (e.g. --ports=500/udp,4500/udp)"
    exit 1
fi


### Convert comma-separated list to array
IFS=',' read -ra PORTS <<< "$PORT_LIST"


### Apply rules
for PORT_SPEC in "${PORTS[@]}"; do
    if [[ "$ACTION" == "enable" ]]; then
        ### Add UFW rule for given port
        ufw allow "$PORT_SPEC" comment "VPN rule for $PORT_SPEC"
        echo "Enabled UFW rule for $PORT_SPEC"
    elif [[ "$ACTION" == "disable" ]]; then
        ### Delete UFW rule for given port
        ufw delete allow "$PORT_SPEC"
        echo "Disabled UFW rule for $PORT_SPEC"
    fi
done


### Show current UFW status
echo
echo "Current UFW rules:"
ufw status numbered
