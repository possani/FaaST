# Master Thesis

## Requirements

The following components are necessary for setting up and interacting with the cluster:
 * [terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)
 * [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
 
## Get Started

Clone the repository and go to the root directory:

```bash
git clone git@github.com:possani/master-thesis.git
cd master-thesis
```

Create a key-pair in the cloud

TODO

Replace the key variables in the config files accordingly

```bash
variables.tf (instance_keypair_name)
variables.tf (cloud_cluster_ssh_key)
ansible/ansible.cfg (private_key_file)
```

Download the credentials from the cloud and source it

```bash
. xxxxxxx-openrc.sh
```

Initialize the terraform providers

```bash
terraform init
```

Bootstrap the cluster

```bash
terraform apply
yes
```