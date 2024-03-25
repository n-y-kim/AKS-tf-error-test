variable "resource_count" {
  description = "The number of resource groups to create"
  default     = 1
}

variable "cluster_name" {
  default = "tf-error-test-cluster"
}

variable "dns_prefix" {
  default = "tf-test"
}

variable "agent_count" {
  default = 3
}

# variable "client_id" {
#   default = "CLIENT_ID"
#   description = "Service principal id"
# }

# variable "client_secret" {
#   default = "CLIENT_SECRET"
#   description = "Service principal secret"
# }

variable "rg-location" {
  default = "eastus"
}