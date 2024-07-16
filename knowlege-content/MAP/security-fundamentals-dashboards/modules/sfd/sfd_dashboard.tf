# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


locals { 
    # iam_dashboard_domainname = data.oci_identity_domain.oci_dashboard_identity_domain.display_name
    regions_map              = { for r in data.oci_identity_regions.these.regions : r.key => r.name } # All regions indexed by region key.
    sfd_repo                 = "https://raw.githubusercontent.com/oracle-quickstart/oci-o11y-solutions/main/knowlege-content/MAP/security-fundamentals-dashboards/"
    dashboard_names          = toset(["Identity%20Security.json","Network%20Security.json","Security%20Operations.json"])
    
}

data "oci_identity_regions" "these" {}
data oci_identity_tenancy tenancy {
    tenancy_id = var.tenancy_ocid
}

data "http" "security_dashboards" {
  for_each = local.dashboard_names
    url = "${local.sfd_repo}${each.value}"
    request_headers = {
      Accept = "application/json"
  }
}

data "oci_logging_log_groups" "oci_log_groups" {
    #Required
    compartment_id = var.sfd_compartment_ocid

    #Optional
    display_name = "_Audit_Include_Subcompartment"
    #is_compartment_id_in_subtree = var.log_group_is_compartment_id_in_subtree
}


# output "audit_id" {
#     value = data.oci_logging_log_groups.oci_log_groups.id
# }

data "oci_objectstorage_namespace" "ns" {
  compartment_id             = var.sfd_compartment_ocid
}

data "oci_log_analytics_namespaces" "sfd_dashboard_namespaces" {
  compartment_id = var.tenancy_ocid
}

resource "oci_log_analytics_namespace" "sfd_dashboard_namespace" {
  count = data.oci_log_analytics_namespaces.sfd_dashboard_namespaces.namespace_collection.0.items.0.is_onboarded ? 0 : 1
  namespace = data.oci_objectstorage_namespace.ns.namespace
  is_onboarded = true
  compartment_id = var.tenancy_ocid
}


resource "time_sleep" "wait_40_seconds" {
  count = data.oci_log_analytics_namespaces.sfd_dashboard_namespaces.namespace_collection.0.items.0.is_onboarded ? 0 : 1
  depends_on = [oci_log_analytics_namespace.sfd_dashboard_namespace]
  create_duration = "40s"
}

resource "oci_management_dashboard_management_dashboards_import" "iam_dashboard_import" {
  for_each = local.dashboard_names
    #import_details = replace(replace(data.http.security_dashboards[each.key].response_body,"${"$"}{compartment_ocid}","${var.sfd_compartment_ocid}"),"2507e19d927d458a0cafe461cd07c5ae","${var.sfd_compartment_ocid}")
    #import_details = replace(data.http.security_dashboards[each.key].response_body,"/(\"compartmentId\":\\s*\")\\S+\"/","\"compartmentId\": \"${var.sfd_compartment_ocid}\"")
    import_details = replace(data.http.security_dashboards[each.key].response_body,"/(\"compartmentId\":\\s*\")\\S+\"/","$${1}${var.sfd_compartment_ocid}\"")
    #import_details = templatefile(format("%s/%s/%s", path.root,"resources", each.value), {"compartment_ocid" : "${var.sfd_compartment_ocid}"})
}


# Create a log group with required parameters
resource "oci_log_analytics_log_analytics_log_group" "iam_dashboard_log_group" {

  count = (var.create_service_connector_audit  == true ) ? 1 : 0
  compartment_id             = var.sfd_compartment_ocid
  #namespace                  = oci_log_analytics_namespace.iam_dashboard_namespace.namespace
  namespace = data.oci_log_analytics_namespaces.sfd_dashboard_namespaces.namespace_collection.0.items.0.is_onboarded ? data.oci_log_analytics_namespaces.sfd_dashboard_namespaces.namespace_collection.0.items.0.namespace : oci_log_analytics_namespace.sfd_dashboard_namespace[count.index].namespace
  display_name               = var.logging_analytics_log_group_name
}

# Get details of above created log group with required parameters
data "oci_log_analytics_log_analytics_log_group" "iam_dashboard_log_group_details" {
  count = (var.create_service_connector_audit  == true ) ? 1 : 0
  #namespace                  = data.oci_log_analytics_namespaces.iam_dashboard_namespaces.namespace_collection.0.items.0.namespace
  namespace = data.oci_log_analytics_namespaces.sfd_dashboard_namespaces.namespace_collection.0.items.0.is_onboarded ? data.oci_log_analytics_namespaces.sfd_dashboard_namespaces.namespace_collection.0.items.0.namespace : oci_log_analytics_namespace.sfd_dashboard_namespace[count.index].namespace
  log_analytics_log_group_id = oci_log_analytics_log_analytics_log_group.iam_dashboard_log_group[count.index].id
}

resource "oci_sch_service_connector" "iam_dashboard_service_connector" {
  count = (var.create_service_connector_audit  == true ) ? 1 : 0
  compartment_id = var.sfd_compartment_ocid
  #defined_tags  = {"${oci_identity_tag_namespace.tag-namespace1.name}.${oci_identity_tag.tag1.name}" = "updatedValue"}
  description    = "Used to populate Logging Analytics with OCI Audit Logs"
  display_name   = "IAM Identity Domain Audit to Logging Analytics"


  source {
    kind = "logging"
    #Audit
    log_sources {
      compartment_id = var.sfd_compartment_ocid
      log_group_id   = "_Audit"
      log_id = ""
    }
  }
  target {
    kind            = "loggingAnalytics"
    log_group_id    = data.oci_log_analytics_log_analytics_log_group.iam_dashboard_log_group_details[count.index].id
  }

  state = var.service_connector_audit_state
}

resource "oci_identity_policy" "connectorpolicy_logginganalytics" {
  count = (var.create_service_connector_audit  == true ) ? 1 : 0
  name           = "SFD_Dashboard_ConnectorPolicy_LoggingAnalytics"
  description    = "Policy to allow Service Connector to upload logs to a Logging Analytics Log Group"
  compartment_id = var.sfd_compartment_ocid
  provider = oci.home

  statements = [
    "allow any-user to {LOG_ANALYTICS_LOG_GROUP_UPLOAD_LOGS} in compartment id ${var.sfd_compartment_ocid} where all {request.principal.type='serviceconnector', target.loganalytics-log-group.id='${data.oci_log_analytics_log_analytics_log_group.iam_dashboard_log_group_details[count.index].id}', request.principal.compartment.id='${var.sfd_compartment_ocid}'}"
  ]
}