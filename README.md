The repository provides definitions used to manage a VM that runs Hashicorp Vault for a Tapis installation.  See https://tapis.readthedocs.io/en/latest/deployment/vault.html for installation instructions.

Administrative Procedures for SK/Vault
======================================

A) General Information
----------------------
SK's vault roles, policies and other definitions are currently kept in this reposityr. Clone the tapis-project/tapis-vault-vm.git project to work with the definitions.

For this discussion, we assume the Vault is installed on a VM named **tapis-vault** at port 8200.

The following environment variables are used throughout this document:

VAULT_TOKEN - the root vault token created and displayed on Vault installation
SK_ADMIN_TOKEN - SK token with some root-like admin permissions
SK_TOKEN - SK token with the minimal permissions necessary for SK execution

B) Get shortlived (10 min) secret needed for SK_TOKEN generation
----------------------------------------------------------------
curl -X POST -H "X-Vault-Token: $VAULT_TOKEN" http://tapis-vault:8200/v1/auth/approle/role/sk/secret-id | jq

C) Get shortlived (10 min) secret needed for SK_ADMIN_TOKEN generation
----------------------------------------------------------------------
curl -X POST -H "X-Vault-Token: $VAULT_TOKEN" http://tapis-vault:8200/v1/auth/approle/role/sk-admin/secret-id | jq

D) Get the Vault-generated, perminent role-id needed for SK_TOKEN generation
----------------------------------------------------------------------------
curl -H "X-Vault-Token: $VAULT_TOKEN" http://tapis-vault:8200/v1/auth/approle/role/sk/role-id | jq

E) Get the Vault-generated, perminent role-id needed for SK_ADMIN_TOKEN generation
----------------------------------------------------------------------------------
curl -H "X-Vault-Token: $VAULT_TOKEN" http://tapis-vault:8200/v1/auth/approle/role/sk-admin/role-id | jq

F) Generate SK_TOKEN from command line
--------------------------------------
1. Clone the cic/tapis-vault repo as mentioned above.
2. Copy tapis-vault/roles/sk-login.json to your current working directory.
3. Copy the secret_id value acquired from B) into your copy of sk-login.json.
4. curl -X POST --data @sk-login.json http://tapis-vault:8200/v1/auth/approle/login | jq  

G) Generate SK_ADMIN_TOKEN from command line
--------------------------------------------
1. Clone the cic/tapis-vault repo as mentioned above.
2. Copy tapis-vault/roles/sk-admin-login.json to your current working directory.
3. Copy the secret_id value acquired from C) into your copy of sk-admin-login.json.
4. curl -X POST --data @sk-admin-login.json http://tapis-vault:8200/v1/auth/approle/login | jq  

H) Vault parameters needed to start SK in DEV environment
---------------------------------------------------------
In addition to the non-vault environment variables injected by Kube into the SK container at start up, these vault variables should also be injected:

    Env Parameter             Value
    -------------             -----
    tapis.sk.vault.disable    false
    tapis.sk.vault.address    http://tapis-vault:8200
    tapis.sk.vault.secretid   recently generated secret_id from B)
    tapis.sk.vault.roleid     role_id generated from D)
      
If tapis.sk.vault.disable=true, then SK will start up in authorization-only mode, which means all secret APIs will fail but authorization APIs will still work.

The secret-id's generated in steps B and C have a 10 minute TTL.  The role-id's generated in steps D and E are generated by Vault once and then reused from that point on, though Vault is free to change the role-id whenever the role changes.

Note that the secret-id command returns a secret_id field; the role-id command returns a role_id field.  

Create a Tapis Root Token
-------------------------
The recommendation is that the root token generated by Vault upon initialization
should not be used regularly.  Instead, it should be squirreled away and only used 
during Vault initialization and in emergencies.  Here's how to create another
root token that can be used to safeguard the original root token.

1. Create input file tapisroot.json:
    {
        "display_name": "tapisroot",
        "policies": [ "root" ],
        "ttl": 0 
    }

2. Export the original root token to VAULT_TOKEN and issue: 
    curl -X POST -s -H "X-Vault-Token: $VAULT_TOKEN" --data @tapisroot.json https://tapis-vault-stage.tacc.utexas.edu:8200/v1/auth/token/create | jq
 