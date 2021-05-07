variable "client_id" {
    type = string
    sensitive = true
}

variable "client_secret" {
    type = string
    sensitive = true
}

variable "subscription_id" {
    type = string
    sensitive = true
}

variable "tenant_id" {
    type = string
    sensitive = true
}

variable "managed_image_name" {
    type = string
    default = "ghrunner"
}

variable "managed_image_resource_group_name" {
    type = string
    default = "rg-ghrunner"
}