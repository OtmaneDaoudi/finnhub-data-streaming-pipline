#!/bin/bash
# This script creates the infrastructure in GCP

# Source environment variables
source ./scripts/env.sh

# Remove the existing key file if it exists
# if [ -f "$TF_VAR_gcpPrivateKeyFile" ]; then
#     # Remove the .ssh directory and its contents
#     rm -r ~/.ssh
# fi

# Generate the RSA key pair
# ssh-keygen -t rsa -P "" -f "$TF_VAR_gcpPrivateKeyFile" -C "$TF_VAR_gcpUserID" -b 2048

# Change directory to the provisioning folder
cd ./provisionning

# Initialize Terraform
terraform init

# Apply Terraform configuration with auto-approval
# Run the Terraform apply command and capture the output
terraform apply -auto-approve

# Move back to the scripts folder
cd ../