# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.



variable "sfd_compartment_ocid" {
    type = string
  }

variable "tenancy_ocid" {}

variable "user_ocid" {
  default = ""
}
variable "fingerprint" {
  default = ""
}
variable "private_key_path" {
  default = ""
}
variable "private_key_password" {
  default = ""
}
variable "region" {}


# variable iam_dashboard_import_custom_content_file {
#   default = "./resources/ociAuditLogSource.zip"
# }

# #variable iam_dashboard_import_custom_content_namespace {}

# variable iam_dashboard_custom_content_is_overwrite {
#   type = bool
#   default = true
# }

variable create_service_connector_audit {
  type = bool
  default = false
}

variable logging_analytics_log_group_name {
  type = string
  default = null
}

variable service_connector_audit_state {
  type = string
  default = "INACTIVE"
}

variable configure_flow_logs {  #RM use
  type = bool
  default = false
}

variable flow_logs_log_group {
  type = string
  default = "sfd-flow-logs-log-group"
}

variable subnet_flow_logs_compartment_ids {
  type = list(string)
  default = null
}

variable first_subnet_flow_logs_compartment_id {  #RM use
  type = string
  default = null
}

variable second_subnet_flow_logs_compartment_id {  #RM use
  type = string
  default = null
}

variable third_subnet_flow_logs_compartment_id {  #RM use
  type = string
  default = null
}

variable add_second_subnet_flow_logs_compartment {  #RM use
  type = bool
  default = false
}

variable add_third_subnet_flow_logs_compartment {  #RM use
  type = bool
  default = false
}


