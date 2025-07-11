variable "storage_class_name" {
  description = "Name of the storage class"
  type        = string
}

variable "provisioner" {
  description = "Provisioner to use (e.g., dobs.csi.digitalocean.com)"
  type        = string
}

variable "parameters" {
  description = "Parameters to pass to the provisioner"
  type        = map(string)
  default     = {}
}

variable "reclaim_policy" {
  description = "Reclaim policy (e.g., Retain or Delete)"
  type        = string
  default     = "Delete"
}

variable "volume_binding_mode" {
  description = "Binding mode for volumes"
  type        = string
  default     = "Immediate"
}

variable "allow_volume_expansion" {
  description = "Allow volume expansion"
  type        = bool
  default     = true
}

variable "pvc_name" {
  description = "Name of the default PVC"
  type        = string
}

variable "namespace" {
  description = "Namespace for the PVC"
  type        = string
}

variable "storage_size" {
  description = "Size of the requested PVC"
  type        = string
}
