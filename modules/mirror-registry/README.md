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
3. **Trust + oc-mirror** — The registry TLS cert is signed by an offline CA in Terraform output (`mirror_registry_additional_trust_bundle`). The **bastion** user-data installs that CA into `/etc/pki/ca-trust` when the mirror module is enabled, so `oc mirror` trusts `docker://mirror.<base_domain>/...` without TLS errors. On any other host (including an older bastion), install the CA manually (see root [`README.md`](../../README.md) disconnected section). Then mirror using **v2** and the repo example [`scripts/imageset-config.yaml.example`](../../scripts/imageset-config.yaml.example) (`--workspace`, `--v2`).
4. **Deploy forge** — `terraform output -json > foundry_output.json` includes both `mirror_registry_url` and `mirror_registry_additional_trust_bundle`; gryphon-forge merges them when you pass `-e @foundry_output.json`. Set `openshift_install_release_image_override` in Forge to the mirrored payload digest from `oc-mirror` output.

## TLS / trust bundle

The module no longer uses an OpenSSL CN-only certificate on the instance. Trust **gryphon-forge** with the CA from Terraform output (`mirror_registry_additional_trust_bundle`), not the server cert file on disk (unless you know you need the leaf). The same CA must be trusted on hosts that run `oc mirror` against this registry (bastion automation or manual `update-ca-trust`).

Optional extra DNS SANs: set root variable `mirror_registry_tls_extra_san_dns_names` (list of strings).

**Replacing an existing registry instance** after upgrading this module: EC2 `user_data` changes force instance replacement on apply, or run `terraform apply -replace='module.mirror_registry[0].aws_instance.mirror_registry'`.
