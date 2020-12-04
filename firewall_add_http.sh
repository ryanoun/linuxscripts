#!/bin/bash
# Add HTTP/80 + 443 service

dnf install firewalld -y
systemctl enable firewalld
systemctl start firewalld

echo -e "Adding: $(firewall-cmd --zone=public --add-service=http --permanent)";
echo -e "Adding: $(firewall-cmd --zone=public --add-service=https --permanent)";
echo -e "Reloading: $(firewall-cmd --reload)";
