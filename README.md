# oci-o11y-solutions

Oracle Observability and Management Solution Templates

This is an example on how to export, add & deploy  dashboards in Logging Analytics.

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?region=home&zipUrl=https://github.com/oracle-quickstart/oci-o11y-solutions/releases/download/0.1.1/o11_solutions.zip)


## Steps for Sharing your Logging Analytics Dashboards

## Create your dashboard in Logging Analytics 

Note the dashboard OCID and take a screenshot

     
## Fork this repo https://github.com/oracle-quickstart/oci-o11y-solutions/fork

## Clone the forked repo in OCI Cloud Shell or your Local Workstation

    git clone https://github.com/<your-github-id>/oci-o11y-solutions.git
    cd oci-o11y-solutions
    git branch -b my-branch main

## Add dashboard files
    cd content/dashboards

### Export Dashboard json
    export DASHBOARD_ID=”<OCID….>”
    oci raw-request --http-method GET --target-uri https://managementdashboard.us-phoenix-1.oci.oraclecloud.com/20200901/managementDashboards/${DASHBOARD_ID} | jq .data  | jq '.compartmentId = "${compartment_ocid}"' | jq -n -s '{dashboards: inputs}' >> my-dashboard.json
    
Copy the dashboard screenshot to contents/documentation directory.
    
    cp /path/to/my-dashboard.png  contents/documentation

### Commit and push changes
    git add contents/dashboards/my-dashboard.json
    git add contents/documentation/my-dashboard.png
    git commit -a -m "Adding my new dashboard and screenshot" 
    git push origin my-branch

### Create Pull Request on your forked Github repo to merge your new dashboards to Oracle-quickstart main repo for publishing.
