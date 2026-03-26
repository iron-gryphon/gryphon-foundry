# Mirror Registry Module

Deploys a container registry in the Nest VPC for disconnected OpenShift installs. The Vault (air-gapped) pulls images from this registry via VPC peering.

## Usage

Enable in `main.tf`:

```hcl
variable "create_mirror_registry" {
  default = true
}
```

## Outputs

- `mirror_registry_url` — DNS name (e.g. `mirror.fsi.internal`) for install-config
- `mirror_registry_public_ip` — For oc-mirror from outside the VPC
- `mirror_registry_additional_trust_bundle` — PEM of the offline CA that signs the registry certificate (for gryphon-forge `install-config` `additionalTrustBundle`)

## Workflow

1. **Terraform apply** — Creates EC2 with `registry:2` over HTTPS. TLS is generated during apply: a short-lived CA plus a server certificate whose **Subject Alternative Names** include `mirror.<base_domain>` (required by RHCOS / Go TLS clients).
2. **Route53** — `mirror.<base_domain>` points to the registry (when ocp_internal zone exists)
3. **Run oc-mirror** — From bastion (has internet): `oc mirror run --config imageset-config.yaml`
4. **Deploy forge** — `terraform output -json > foundry_output.json` includes both `mirror_registry_url` and `mirror_registry_additional_trust_bundle`; gryphon-forge merges them when you pass `-e @foundry_output.json`.

## TLS / trust bundle

The module no longer uses an OpenSSL CN-only certificate on the instance. Trust **gryphon-forge** with the CA from Terraform output (`mirror_registry_additional_trust_bundle`), not the server cert file on disk (unless you know you need the leaf).

Optional extra DNS SANs: set root variable `mirror_registry_tls_extra_san_dns_names` (list of strings).

**Replacing an existing registry instance** after upgrading this module: EC2 `user_data` changes force instance replacement on apply, or run `terraform apply -replace='module.mirror_registry[0].aws_instance.mirror_registry'`.
