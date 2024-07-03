#!/bin/bash
# This script configures the infrastructure in GCP using Ansible

# Change directory to the scripts folder
cd /tmp/scripts

# Source environment variables
source env.sh

# Generate IPs for the infrastructure
source generate-ips.sh

# Create hosts file for Ansible
source create-hosts.sh

# Configure HAProxy
source haproxy.sh

# Fetch the IP of the Load Balancer
source fetch-lb-ip.sh

# Change directory to the configuration folder
cd /tmp/configuration

# Create etcd directory, ignore error if it already exists
mkdir etcd 2> /dev/null

# Run Ansible playbooks to configure the infrastructure
ansible-playbook configure-lb.yaml
ansible-playbook conf-k8s-modules.yaml
ansible-playbook install-config-containerd.yaml
ansible-playbook install-k8s-tools.yaml
ansible-playbook master-playbook.yaml
ansible-playbook worker-playbook.yaml
ansible-playbook helm-prometheus-grafana.yaml
ansible-playbook deploy-spark-operator.yaml
ansible-playbook deploy-cassandra.yaml
ansible-playbook deploy-kafka-stack.yaml
ansible-playbook submit-spark-job.yaml
ansible-playbook deploy-ingestion.yaml
ansible-playbook update-lb-ports.yaml
# Change back to the /tmp directory
cd /tmp