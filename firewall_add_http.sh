#!/bin/bash
# Add HTTP/80 + 443 service

systemctl start firewalld

echo -e "Adding: $(firewall-cmd --add-service=http --permanent)";
echo -e "Reloading: $(firewall-cmd --reload)";

