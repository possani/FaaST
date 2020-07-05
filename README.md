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
variables.tf (ssh_key_file)
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
terraform apply -auto-approve
```

## Access the Dashboards with Kubectl

Select a VM and start a proxy

```bash
ssh -L 8001:0.0.0.0:8001 <vm-user>@<vm-ip-address> -i <private-key-path>
kubectl proxy
```

### Kubernetes Dashboard

http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

token: ansible/from_remote/<instance_name>/admin-user-token.out

### Grafana Monitoring

http://localhost:8001/api/v1/namespaces/prometheus-operator/services/http:prometheus-operator-grafana:service/proxy/

user: admin
pw: prom-operator

### Grafana Openwhisk

http://localhost:8001/api/v1/namespaces/openwhisk/services/http:owdev-grafana:http/proxy/

## Access the cluster with Kubectl

export KUBECONFIG=ansible/from_remote/<instance_name>/etc/kubernetes/admin.conf

> **_NOTE:_**  It takes about 10 min to run.
