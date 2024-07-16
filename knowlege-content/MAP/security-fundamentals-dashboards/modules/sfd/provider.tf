# Copyright (c) 2021 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.



provider "oci" {
  region               = var.region
  tenancy_ocid         = var.tenancy_ocid
  user_ocid            = var.user_ocid
  fingerprint          = var.fingerprint
  private_key_path     = var.private_key_path
  private_key_password = var.private_key_password
}

provider "oci" {
  alias = "token"
  auth = "SecurityToken"
  config_file_profile = "IDDomain"
  region               = var.region
}

provider "oci" {
  alias                = "home"
  region               = lookup(local.regions_map, data.oci_identity_tenancy.tenancy.home_region_key)
  tenancy_ocid         = var.tenancy_ocid
  user_ocid            = var.user_ocid
  fingerprint          = var.fingerprint
  private_key_path     = var.private_key_path
  private_key_password = var.private_key_password
}
