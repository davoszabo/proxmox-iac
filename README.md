# Proxmox IAC

## Description
Provisioning VMs from cloudinit image using Ansible and Terraform (OpenTofu) in a Proxmox environment securely.

### Variable processing
Variables for the VM and cloud-init config are processed by the `vm_prefix` variable. By default it aggregates all variables starting with the `VM_` prefix (or what ever you have chosen), and creates a map from the inventory.

For each VM the:

- **ansible_host** (IP)
- **vmid** (ID)

are mandatory to be defined one-by-one!

### Example output
```
    vm_map:
        example-cluster-01:
            config:
                agent: true
                cores: 2
                cpu_type: host
                gateway: 10.120.50.254
                memory: 2048
                password: abc1234
                ssh_pubkey: |-
                    ssh-rsa AAAA== example-cluster
                storage_pool: vmdata
                storage_size_gb: 16
                storage_ssd: true
                tags:
                - example
                target_node: pvehost-001
                template_id: 9000
                user: test
            id: 5050
            ip: 10.120.50.50
            name: example-cluster-01
        example-cluster-02:
            ...
```

## Provision

### Prerequisites
Use the devcontainer or install the utilities on your host present inside `.devcontainer/Dockerfile`.

### Setup
By default password login is disabled so we have to generate SSH key for the VMs with `ssh-keygen`. Later the public key should be placed inside the vault with encryption. The private key has to be placed in `ansible_ssh_private_key_file: "~/.ssh/rke2-test"` so that the playbook can also communicate with the node.

Create inventory and corresponding vault. (Check examples under `inventory/`.)

### Test run
Start provisioning (always use `--check` before execute). You can also use tags with `-t`.

```sh
ansible-playbook playbooks/terraform-provision.yaml -i inventory/rke2-cluster-test -t <prov|post> --check
```

