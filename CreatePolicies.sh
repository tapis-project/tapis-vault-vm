#!/bin/bash

# This program establishes the Vault roles and policies used by the 
# Tapis Security Kernel.  It should be run once when a new Vault is created
# and after the AppRole authentication, the KV v2 secrets engine and UserPassword
# secrets engine are enabled.

# This program expects the root token of the target Vault
# to be assigned to the VAULT_TOKEN environment variable.
if [ -z "$VAULT_TOKEN" ]; then
    echo "The environment variable VAULT_TOKEN must be assigned the"
    echo "root token of the target Vault instance."
    exit 1
fi

# Check that we are running in the proper directory.
curdir=${PWD##*/}
if [ "$curdir" != "tapis-vault" ]; then
    echo "This command must be run from the tapis-vault directory."
    exit 1
fi

# Check that there's at least 1 command line argument.
if [ $# -eq 0 ]; then
    echo "Please provide the fully qualified DNS name of the Vault server."
    echo "Example:  CreatePolicies tapis-vault-stage.tacc.utexas.edu"
    exit 1
fi
vaultServer=$1


# Create the admin policies.
cd policies/sk-admin
for i in sk-admin-acl sk-admin-approle sk-admin-auth sk-admin-kv2 sk-admin-userpass
do
  echo ---
  echo $i
  data=$( cat ${i}-policy.hcl )
  payload="$( jq -nc --arg str "$data" '{"policy": $str}' )"
  curl -X PUT -H "X-Vault-Token: $VAULT_TOKEN" -d "$payload" https://$vaultServer:8200/v1/sys/policies/acl/tapis/${i} 
done
cd ../..

# Create the regular policies.
cd policies/sk
for i in sk-acl sk-approle sk-token
do
  echo ---
  echo $i
  data=$( cat ${i}-policy.hcl )
  payload="$( jq -nc --arg str "$data" '{"policy": $str}' )"
  curl -X PUT -H "X-Vault-Token: $VAULT_TOKEN" -d "$payload" https://$vaultServer:8200/v1/sys/policies/acl/tapis/${i}  
done
cd ../..

