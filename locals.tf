# Copyright (c) 2023, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  namespace                    = data.oci_objectstorage_namespace.os_namespace.namespace
  timestamp                    = formatdate("YYYYMMDDhhmmss", timestamp())
}
