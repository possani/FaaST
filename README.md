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
terraform apply -auto-approve
```

## Access the Dashboards - Using the public IP and NodePort

Get the NodePort for the specified service and access the following URL:

https://<floating_ip>:<service_port>/

### Kubernetes Dashboard

```bash
kubectl -n kubernetes-dashboard get svc kubernetes-dashboard -o jsonpath='{.spec.ports[0].nodePort}'
```

### Grafana Monitoring

```bash
kubectl get svc prometheus-operator-grafana -o jsonpath='{.spec.ports[0].nodePort}'
```

user: admin
pw: prom-operator

### Grafana Openwhisk

```bash
kubectl -n openwhisk get svc owdev-nginx -o jsonpath='{.spec.ports[0].nodePort}'
```

## Access the Dashboards - Using kubectl

Start a proxy in the backgroud

```bash
kubectl proxy &
```

### Kubernetes Dashboard

http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

### Grafana Monitoring

http://localhost:8001/api/v1/namespaces/prometheus-operator/services/http:prometheus-operator-grafana:service/proxy/

user: admin
pw: prom-operator

### Grafana Openwhisk

http://localhost:8001/api/v1/namespaces/openwhisk/services/http:owdev-nginx:http/proxy/monitoring/dashboards

> **_NOTE:_**  It takes about 15 min to run.
