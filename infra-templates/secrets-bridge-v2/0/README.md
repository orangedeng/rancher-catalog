# Rancher Secrets Bridge v2

## Purpose

This volume driver delivers access tokens per-container to authenticate with Hashicorp Vault.

## Terms

**Instance token:** Vault token to be used by the container.

**Intermedate token:** A wrapped response token from Vault to be used to access the instance token. These are short lived

**Issuing token:** Vault token that will be assigned a role can create all intermediate and instance tokens. If this token expires all tokens issued will ALSO expire.

## Setup

### Vault

Create a new role in Vault that encompases all of the policies that will be used in an environment. Applications policy scope can be limited to a subset when requesting an access token.

Create a policy that can be used for issuing token.
```
path "auth/token/create/<role_name>" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Have access to revoke accessors
path "auth/token/revoke-accessor" {
  capabilities = ["update", "create"]
}

# Limit scope of grantor-default by denying access to all secrets
path "secret/*" {
  capabilities = ["deny"]
}
```

`vault policy-write <role>-issuing issuing-token.hcl`

Create an issuing token 
This token should:
* Be renewable
* Have a  TTL of 3-12 hours. (Must be greater then 5 minutes)
* Be an orphan so that it isn't accidentally expired.

`vault token-create -role=<role> -policy=<role>-issuing -ttl=3h -orphan`

When creating the issuing token, you can add the following metadata to configure how intermediate and instance tokens will be configured.

* `-metadata=ttl=5m` (default: 5m) sets the instance token TTL.

* `-metadata=intermediateTTL=5m` (default: 5m) sets the TTL for the intermediate token. Once this expires the instance token will no longer be accessible.

* `-metadata=renewable=false` (default: true) sets if instance tokens can be renewed.

### Launching this Template

Information required:
 - Issuing token stored as Rancher Secret
 - Vault Server URL
 - Vault issuing role

### Custom CA/Self signed certs

In order to for the Vault Token Driver to communicate with a Vault server behind a self signed certificate, the ca.pem file will need to be added to /var/lib/rancher/

## Using

### Getting Tokens

In the example below, the containers in the service testing will get tokens with the default and app1 policies applied.

```yaml
version: '2'
services:
  testing:
    image: alpine
    volumes:
      - vault-token-0:/testing
    tty: true
    stdin_open: true
    command: sh
volumes:
  vault-token-0:
    driver: secrets-bridge-v2
    driver_opts:
      policies: "default,app1"
    per_container: true
```

The container will get an intermediate token written in the file `/testing/token`. The `/testing` folder is a tmpfs volume mount. The container must use this token, to retrieve the instance token.

The token can be retrieved with a call as follows:

`curl -X POST -H 'X-Vault-Token: <contents of token file>' https://<vault_addr>:<vault_port>/v1/sys/wrapping/unwrap`

Using the retrieved token you can now access Vault within the scope of the assigned policies.

To change the policies of the token, a new volume name needs to be assigned. Incrementing '0'  will create a new volume after upgrade. 

## Security Considerations

### Security scope

This stack continues with the Rancher environment as the security boundary. There are some mechanisms in place to mitigate attacks and make it more difficult for an attacker to gain access to Vault.

Requesting tokens from a host, require a signed request using the hosts private key file. This signature if verified using the public key stored in Rancher Server. The key pair is generated during the hosts registration process. Signatures are only valid for 5 minutes. The response on a token create
request is RSA Encrypted using the hosts public key and is only accessible using the private key of the host that signed the request. This should mitigate replay attacks should a third party obtain a request form the network on a remote host.

The issuing token is delivered via Rancher Secret. It is the most secure method available in Rancher. This does mean at least one host in an environment will contain the Vault issuing token. This token should only be allowed to issue tokens scoped to the Rancher enviornment it is being used in. 