#!/bin/bash
# This script fetches the IP of the Load Balancer from output.json and writes it to a file

# Parse output.json
output=$(cat output.json)

# Fetch load balancer instance
gateway_server_instance=$(echo "$output" | jq -r '.gateway_ip')

# Write the Load Balancer IP to the lb-ip file in the configuration directory
# Overwrite the file if it already exists
cat > ../configuration/lb-ip <<EOF
$gateway_server_instance:6443
EOF