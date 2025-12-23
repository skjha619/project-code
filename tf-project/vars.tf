variable "rg_name" {
    description = "resource group name"
    default = "acr365s35"
  
}
variable "image" {
  description = "ACR image (including registry login server)"
  default     = "acr365s35.azurecr.io/voting-app:green"
}


variable "revision_suffix" {
  default = "green-v1"
}