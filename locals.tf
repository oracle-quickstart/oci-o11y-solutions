
locals {
  namespace                    = data.oci_objectstorage_namespace.os_namespace.namespace
  timestamp                    = formatdate("YYYYMMDDhhmmss", timestamp())
}
