# oci-o11y-solutions
Oracle Observability and Management Solution Templates

This is an example on how to export, add & deploy  dashboards in Logging Analytics.

## Sharing new Logging Analytics Dashboards some chars

### Export Dashboard json
    export DASHBOARD_ID=”<OCID….>”
    oci raw-request --http-method GET --target-uri https://managementdashboard.us-phoenix-1.oci.oraclecloud.com/20200901/managementDashboards/${DASHBOARD_ID} | jq .data  | jq '.compartmentId = "${compartment_ocid}"' | jq -n -s '{dashboards: inputs}'
 
### Clone the Module
Now, you'll want a local copy of this repo. You can make that with the commands:

    git clone https://github.com/oracle-quickstart/oci-o11y-solutions.git
    cd oci-o11y-solutions
    git branch -b my-branch main

### Add dashboard files
    cp my-dashboard.json contents/dashboards 
    cp my-dashboard.png  contents/documentation

### Commit and push changes
    git add contents/dashboards/my-dashboard.json
    git add contents/documentation/my-dashboard.png
    git commit -a -m "Adding Dashboard files" 
    git push origin my-branch

### Create Pull Request
