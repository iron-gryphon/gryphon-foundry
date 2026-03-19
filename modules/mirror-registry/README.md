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

## Workflow

1. **Terraform apply** — Creates EC2 with registry:2 (HTTPS, self-signed cert)
2. **Route53** — `mirror.<base_domain>` points to the registry (when ocp_internal zone exists)
3. **Run oc-mirror** — From bastion (has internet): `oc mirror run --config imageset-config.yaml`
4. **Deploy forge** — Pass `mirror_registry_url` from foundry output

## Self-Signed Certificate

The registry uses a self-signed cert. For gryphon-forge, set `mirror_registry_additional_trust_bundle` to the PEM content. Retrieve from the registry host:

```bash
ssh ec2-user@<mirror-registry-ip> "cat /opt/registry/certs/domain.crt"
```
