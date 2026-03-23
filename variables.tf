variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key for server access"
  type        = string
}

variable "server_name" {
  description = "Name of the server"
  type        = string
  default     = "dev-box"
}

variable "location" {
  description = "Hetzner datacenter location"
  type        = string
  default     = "fsn1"
}

variable "server_type" {
  description = "Hetzner server type"
  type        = string
  default     = "cpx42"
}
