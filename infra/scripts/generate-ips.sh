#!/bin/bash

# Read environment variables
workers_count=${TF_VAR_workersVMSCount}
masters_count=${TF_VAR_mastersVMSCount}

# Initialize IP lists
worker_ips=""
master_ips=""

# Generate worker IPs
for ((i=0; i<workers_count; i++)); do
  worker_ips+="192.168.7.2$i,"
done

# Remove trailing comma
worker_ips=${worker_ips%?}

# Generate master IPs
for ((i=0; i<masters_count; i++)); do
  master_ips+="192.168.7.1$i,"
done

# Remove trailing comma
master_ips=${master_ips%?}

# Generate JSON
json=$(cat <<EOF
{
  "worker_ips": "${worker_ips}",
  "master_ips": "${master_ips}",
  "gateway_ip": "192.168.7.30"
}
EOF
)

# Write JSON to output.json
echo "${json}" > output.json