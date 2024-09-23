#!/bin/bash

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
grayColour="\e[0;37m\033[1m"

help_panel() {
    echo -e "${blueColour}./wazuh_setup.sh${endColour}"
    echo -e "${blueColour}[+]${endColour} ${grayColour}Uso:${endColour}"
    echo -e "${greenColour}-h${endColour} ${grayColour}Desplegar las opciones${endColour}"
    echo -e "${greenColour}-r <IP> <NETMASK> <GATEWAY>${endColour} ${grayColour}Configurar red${endColour}"
    echo -e "${greenColour}-w${endColour} ${grayColour}Instalar Wazuh${endColour}"
}

# Static Ip Configuration
red_config() {
    if [[ "$#" -ne 3 ]]; then
        echo -e "${redColour}[!] Error${endColour}"
        echo -e "${greenColour}-r <IP> <NETMASK> <GATEWAY>¨${endColour}"
        return 1
    fi

    echo -e "${blueColour}[-]${endColour} ${grayColour}Configurando red${endColour}"
    
    local ip_address="$1"
    local netmask="$2"
    local gateway="$3"

    disable="network: {config: disabled}"
    disable_path="/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"

    /usr/bin/echo "$disable" | /usr/bin/sudo /usr/bin/tee "$disable_path" > /dev/null

    encoded_config="bmV0d29yazoKICAgIHZlcnNpb246IDIKICAgIHJlbmRlcmVyOiBuZXR3b3JrZAogICAgZXRoZXJu
ZXRzOgogICAgICAgIGVucDBzMzoKICAgICAgICAgICAgZGhjcDQ6IG5vCiAgICAgICAgICAgIGFk
ZHJlc3NlczoKICAgICAgICAgICAgICAgIC0gPElQPi88TkVUTUFTSz4KICAgICAgICAgICAgcm91
dGVzOgogICAgICAgICAgICAgICAgLSB0bzogMC4wLjAuMC8wCiAgICAgICAgICAgICAgICAgIHZp
YTogPEdBVEVXQVk+CiAgICAgICAgICAgICAgICAgIG1ldHJpYzogMTAwCiAgICAgICAgICAgIG5h
bWVzZXJ2ZXJzOgogICAgICAgICAgICAgICAgYWRkcmVzc2VzOgogICAgICAgICAgICAgICAgLSA4
LjguOC44CiAgICAgICAgICAgICAgICAtIDEuMS4xLjEK"

    netplan_path="/etc/netplan/50-cloud-init.yaml"

    network_config=$(/usr/bin/echo "$encoded_config" | /usr/bin/base64 --decode)

    network_config="${network_config//<IP>/$ip_address}"
    network_config="${network_config//<NETMASK>/$netmask}"
    network_config="${network_config//<GATEWAY>/$gateway}"

    /usr/bin/echo "$network_config" | /usr/bin/sudo /usr/bin/tee "$netplan_path" > /dev/null
    /usr/bin/sudo /usr/sbin/netplan apply

    echo -e "${greenColour}[+]${endColour} ${grayColour}Red configurada${endColour}"
    echo -e "${blueColour}[-]${endColour} ${grayColour}Probando conexión${endColour}"

    /usr/bin/sleep 3 > /dev/null

    if /usr/bin/ping -c 1 "$gateway" > /dev/null 2>&1 && /usr/bin/ping -c 1 "8.8.8.8" > /dev/null 2>&1; then
        echo -e "${greenColour}[+]${endColour} ${grayColour}Conexión exitosa${endColour}"
    else
        echo -e "${redColour}[!]${endColour} ${grayColour}Error de conexión${endColour}"
        return 1
    fi

}
# Wazuh Installation
wazuh_install() {
    echo -e "${blueColour}[-]${endColour} ${grayColour}Iniciando instalación${endColour}"

    /usr/bin/curl -sO https://packages.wazuh.com/4.9/wazuh-install.sh && /usr/bin/sudo /usr/bin/bash ./wazuh-install.sh -a
    /usr/bin/sudo /usr/bin/tar -O -xvf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt > ./wazuh-passwords.txt
    /usr/bin/rm ./wazuh-install.sh
    echo -e "${greenColour}[+]${endColour} ${grayColour}Wazuh instalado${endColour}"
}

declare -i parameter_counter=0

while getopts "r:hw" arg; do
    case $arg in 
        h) ;;
        w) let parameter_counter+=1;;
        r) ip_address="$OPTARG"
           netmask="${!OPTIND}"; OPTIND=$((OPTIND + 1))
           gateway="${!OPTIND}"; OPTIND=$((OPTIND + 1))
           let parameter_counter+=2;;
    esac
done

case $parameter_counter in
    1)wazuh_install;;
    2)red_config "$ip_address" "$netmask" "$gateway";;
    3)red_config "$ip_address" "$netmask" "$gateway" && wazuh_install;;
    *)help_panel;;
esac