# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

resource "oci_management_dashboard_management_dashboards_import" "multiple_dashboard_files" { 
  for_each = fileset("./contents/dashboards", "*.json")
    import_details = templatefile(format("%s/%s/%s", path.root,"contents/dashboards", each.value), {"compartment_ocid" : "${var.compartment_ocid}"})
}
