#!/bin/bash
# This script destroys the infrastructure in GCP

# Source environment variables
source ./scripts/env.sh

# Change directory to the provisioning folder
cd ./provisionning

# Destroy the Terraform infrastructure with auto-approval
terraform destroy -auto-approve

# Move back to the scripts folder
cd ../scripts

# Move back to the root directory
cd ../