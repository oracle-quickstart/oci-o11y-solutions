locals {
  

    logging_configuration = {
        default_compartment_id = var.sfd_compartment_ocid
  
        log_groups = {
            SFD-FLOW-LOG-GROUP = {
            name = var.flow_logs_log_group #"vcn-flow-log-group"
            }
        }

        flow_logs = {
            SFD-SUBNET-FLOW-LOGS = {
            log_group_id = "SFD-FLOW-LOG-GROUP"
            target_compartment_ids = var.subnet_flow_logs_compartment_ids != null ? var.subnet_flow_logs_compartment_ids : compact([var.first_subnet_flow_logs_compartment_id,var.second_subnet_flow_logs_compartment_id,var.third_subnet_flow_logs_compartment_id])
            target_resource_type = "subnet"
            }
        }
    }
}



module "flow_logging" {
  count = (var.configure_flow_logs  == true ) ? 1 : 0
  source = "github.com/oracle-quickstart/terraform-oci-cis-landing-zone-observability/logging"
  tenancy_ocid = var.tenancy_ocid
  logging_configuration = local.logging_configuration
}