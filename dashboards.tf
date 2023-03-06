
resource "oci_management_dashboard_management_dashboards_import" "multiple_dashboard_files" { 
  for_each = fileset("./contents/dashboards", "*.json")
    import_details = templatefile(format("%s/%s/%s", path.root,"contents/dashboards", each.value), {"compartment_ocid" : "${var.compartment_ocid}"})
}
