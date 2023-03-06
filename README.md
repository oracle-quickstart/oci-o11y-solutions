# oci-o11y-solutions
Oracle Observability and Management Solution Templates

This is an example on how to deploy dashboards in Logging Analytics.
## Deploy Using the Terraform CLI

### Clone the Module
Now, you'll want a local copy of this repo. You can make that with the commands:

    git clone https://github.com/oracle-quickstart/oci-o11y-solutions.git
    cd oci-o11y-solutions
    ls

### Prerequisites
First off, you'll need to do some pre-deploy setup for Docker and Fn Project inside your machine:

```
sudo su -
yum update
yum install yum-utils
yum-config-manager --enable *addons
yum install docker-engine
groupadd docker
service docker restart
usermod -a -G docker opc
chmod 666 /var/run/docker.sock
exit
curl -LSs https://raw.githubusercontent.com/fnproject/cli/master/install | sh
exit
```
  
### Set Up and Configure Terraform

1. Complete the prerequisites described [here](https://github.com/cloud-partners/oci-prerequisites).

2. Create a `terraform.tfvars` file, and specify the following variables:

```
# Authentication
tenancy_ocid="<tenancy_ocid>"
auth_type="user"
# Config  file is ~/.oci/config 
config_file_profile="DEFAULT"

# Region
region = "<oci_region>"

# Compartment
compartment_ocid = "<compartment_ocid>"

### Create the Resources
Run the following commands:

    terraform init
    terraform plan
    terraform apply


