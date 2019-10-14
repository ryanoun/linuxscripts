#!/bin/bash
# Reset firewall settings in Cent OS 7+

echo -e "\e[93mSERVICES: $(firewall-cmd --list-services)\e[0m"
for srv in $(firewall-cmd --list-services);
    do
        echo -e "\e[92mREMOVING SERIVCE: $srv\e[0m";
        echo -e "\e[96mRESULT: $(firewall-cmd --remove-service=$srv)\e[0m";
done

echo -e "\e[93mREMOVING ALL PORTS\e[0m"
for port in $(firewall-cmd --list-ports);
    do
        echo -e "\e[92mREMOVING PORT $port\e[0m"
        echo -e "\e[96mRESULT: $(firewall-cmd --remove-port=$port)\e[0m";
done

echo -e "\e[93mRE-ADDING DEFAULT (ssh,dhcpv6-client)\e[0m";
echo -e "\e[96mRESULT: $(firewall-cmd --add-service={ssh,dhcpv6-client})\e[0m";

echo -e "\e[93mRUNTIME TO PERMANENT\e[0m";
echo -e "\e[96mRESULT: $(firewall-cmd --runtime-to-permanent)\e[0m";

echo -e "\e[93mRELOADING\e[0m";
echo -e "\e[96mRESULT: $(firewall-cmd --reload)\e[0m"

