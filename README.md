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

## Access the Dashboards via proxy

Select a VM and start a proxy (use **&** for running it in the background)

```bash
ssh -L 8001:0.0.0.0:8001 <vm-user>@<vm-ip-address> -i <private-key-path>
kubectl proxy &
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

user: admin
pw: admin

## Access the cluster with Kubectl

export KUBECONFIG=ansible/from_remote/<instance_name>/etc/kubernetes/admin.conf

## Run a test function

```bash
git clone https://github.com/PrincetonUniversity/faas-profiler.git
cd faas-profiler/functions/ocr-img
wsk action create ocr-img handler.js --docker immortalfaas/nodejs-tesseract --web raw -i
wget -P /mnt/share/ http://dev.blog.fairway.ne.jp/wp-content/uploads/2014/04/eurotext.png
curl -H "Content-Type: image/png" --data-binary @/mnt/share/eurotext.png $(wsk action get ocr-img --url -i) -k -v >output.txt
cat output.txt
```

> **_NOTE:_**  It takes about 10 min for Terraform to run + 5 min for all the Openwhisk Pods to be _Running_/_Completed_.
