# oci-iam-dashboard
[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/gsrz23/oci-iam-dashboard/archive/refs/heads/main.zip)

This repository provides an OCI Logging Analytics Dashboard with some sample widgets to monitor and visualize audit Events for OCI IAM Identity Domains.  The Dashboard will only work in OCI Tenancies that [support IAM Identity Domains](https://docs.oracle.com/en-us/iaas/Content/Identity/getstarted/identity-domains.htm#identity_documentation__updated-identity-domains).  


## Overview

The Audit Logs for OCI IAM Identity Domains can be obtained directly from the OCI Audit Service along with the events from other OCI Services.  The IDCS Rest APIs can still be used, but the Audit Service is more convenient since Audit logs can be easily pushed to Streaming, Object Storage, etc.  The solution in this repository deploys Service Connector Hub to send OCI Audit Logs to Logging Analytics.  It also deploys a sample Dashboard to visualize the audit logs for OCI IAM Identity Domains.

![Dashboard1](images/Dashboard1.png)
![Dashboard3](images/Dashboard3.png)
![Dashboard2](images/Dashboard2.png)


## Resources

The following resources are provisioned with terraform or Resource Manager

- **Logging Analytics**: This is a regional service.  It will be onboarded in the selected region if not available yet.  This can incur  some storage costs.
- **Custom Logging Analytics Fields**: Some custom fields are provisioned in Logging Analytics to support parsing and querying of the OCI Audit Logs.  The fields include: IAM Domain Name, IAM Event ID, IAM Actor Name, IAM Actor Type, IAM Target Name, IAM CLIENT IP, IAM Identity Provider, etc.
- **Custom Logging Analytics Parser**: The parser *IAM Audit Log Format* is used to parse the additionalDetails field from the OCI Audit Logs for Identity Audit Logs.
- **OCI Audit Logs Source**:  The OOB source *OCI Audit Logs* is modified to include the above parser.
- **Loggin Analytics Log Group**: A Log Group named *iam_identity_domain_audit_${var.iam_dashboard_domainname}* is provisioned as the target for Service Connector Hub.
- **Service Connector Hub**: A SCH named *IAM Identity Domain Audit to Logging Analytics* is provisioned to push OCI Audit Logs from a specific compartment to Logging Analytics.
- **IAM Policy**: A Policy named *IAM_Dashboard_ConnectorPolicy_LoggingAnalytics_${var.iam_dashboard_domainname}* that allows SCH to publish logs to the Logging Analytics Log Group.
- **IAM Dashboard**: A sample Loggin Analytics dashboard and with queries based on the custom fields.

## Deployment Notes

The following variables are used for deployment:

- **iam_dashboard_domain_ocid** is the OCID of the existing OCI IAM Identity Domain to be used in the Dashboard queries.  
- **region** is Base Region of the IAM Identity Domain.  Logging Analytics will be onboarded in this region if needed.
- **iam_dashboard_compartmentid** is the compartment ID where the OCI IAM Identity Domain resides and where the dashboard and saved queries are deployed.
- **create_service_connector_audit** set to true if a SCH is needed to push OCI Audit Logs to Logging Analytics.  It's provisioned in the compartment *iam_dashboard_compartmentid*.  The default is *false*
- **service_connector_audit_state** is the initial stated of the SCH if provisioned.  Allowed values are *INACTIVE* (default) and *ACTIVE*
- **logging_analytics_log_group_name** is the name of the Logging Analytics Log Group that will have the Audit Logs.
- **am_dashboard_details**  a template to import dashboards, it's based on the variables *iam_dashboard_domainname* and *iam_dashboard_compartmentid*

To deploy multiple Dashboards use a different stack for each one specifying the respective variables.  

If multiple dashboards are created in the same compartment, there's no need to create a SCH for each.  They can all share one SCH.  The same goes for the Logging Analytics Log Group.

A provisioned Dashboard can't be modified with terraform, any modification to the variable *am_dashboard_details* will create a new dashboard and new saved queries.

Some considerations when using the terraform *destroy* command:
- The Logging Analytics dashboard and customizations are removed from the terraform state but not from Logging Analytics.
- A Dashboard and its Saved Queries have to be removed manually from the console or with API calls.
- The Logging Analytics Log Group won't be destroyed if it contains data.
- Logging Analytics service is not offboarded with the destroy command.
- To remove the Logging Analytics customizations do the following from the Logging Analytics Administration Menu:
    - Edit the OOB Source *OCI Audit Logs* and in the Parser section click Default and then save the source
    - Delete the custom Parser *IAM Audit Log Format*
    - Delete all the custom fields with name that starts with IAM:  IAM Domain Name, IAM EventID, IAM Actor Name, etc.
