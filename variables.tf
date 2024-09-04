variable "address_range" {
  type        = list(string)
  description = "If creating a reverse DNS zone, provide this input with a full cidr range, e.g. 10.0.0.0/16, as it will be split and made if the create_reverse_dns_zone variable is set to true"
  default     = null
}

variable "attempt_reverse_dns_dns_zone_link_to_hub" {
  type        = bool
  description = "Whether the DNS zone being made should be linked to the hub"
  default     = false
}

variable "create_reverse_dns_zone" {
  type        = bool
  description = "Whether or not to create a reverse DNS zone, defaults to false"
  default     = false
}

variable "hub_vnet_id" {
  type        = string
  description = "The ID of the hub vnet"
  default     = null
}

variable "link_to_vnet" {
  type        = bool
  description = "Whether or not the zone should be linked to the vnet, defaults to false"
  default     = false
}

variable "location" {
  description = "The location for this resource to be put in"
  type        = string
}

variable "rg_name" {
  description = "The name of the resource group, this module does not create a resource group, it is expecting the value of a resource group already exists"
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "A map of the tags to use on the resources that are deployed with this module."
}

variable "vnet_id" {
  type        = string
  description = "The vnet id the dns zones should be linked to"
  default     = null
}

variable "vnet_link_name" {
  type        = string
  description = "The name of the vnet link if one is made, defaults to null"
  default     = null
}
