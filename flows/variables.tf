# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

variable "config_file_profile" {
  default = "DEFAULT"
}

variable "auth_type" {
    default = "instance"
}

variable "tenancy_ocid" {
  type        = string
  description = "The OCID of the tenancy."
}

variable "region" {
  type        = string
  description = "OCI region"
}

variable "compartment_ocid" {
  type        = string
  description = "The compartment OCID where all new resources will be created"
}


