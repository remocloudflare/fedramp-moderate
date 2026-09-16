variable "cloudflare_api_token" {
  description = "Cloudflare API token for the commercial control plane. Store only in the ignored terraform.tfvars file."
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare commercial control-plane account ID being onboarded to FedRAMP Moderate."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.cloudflare_account_id))
    error_message = "cloudflare_account_id must be a 32-character lowercase hexadecimal account ID."
  }
}

variable "expected_account_name" {
  description = "Safety check: Terraform refuses to plan if the account ID resolves to a different account name."
  type        = string
}

variable "enable_customer_metadata_boundary" {
  description = "Manage the account-level Customer Metadata Boundary."
  type        = bool
  default     = true
}

variable "customer_metadata_boundary_region" {
  description = "Customer Metadata Boundary storage region. FedRAMP Moderate requires us."
  type        = string

  validation {
    condition     = var.customer_metadata_boundary_region == "us"
    error_message = "FedRAMP Moderate requires customer_metadata_boundary_region = \"us\"."
  }
}

variable "customer_metadata_boundary_allow_out_of_region_access" {
  description = "Allow users routed outside the US boundary to access logs and analytics. FedRAMP Moderate baseline requires false."
  type        = bool

  validation {
    condition     = var.customer_metadata_boundary_allow_out_of_region_access == false
    error_message = "FedRAMP Moderate requires customer_metadata_boundary_allow_out_of_region_access = false."
  }
}

variable "enable_sso_connectors" {
  description = "Create and manage dashboard SSO connectors. Leave false until each email domain and IdP workflow is approved."
  type        = bool
  default     = false
}

variable "sso_connectors" {
  description = "Dashboard SSO connectors keyed by a stable Terraform name. FedRAMP warning language is always enabled by this module."
  type = map(object({
    email_domain       = string
    enabled            = optional(bool, false)
    begin_verification = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for connector in values(var.sso_connectors) :
      can(regex("^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$", connector.email_domain))
    ])
    error_message = "Each SSO email_domain must be a valid DNS domain without @ or a URL scheme."
  }
}

variable "enable_regional_hostnames" {
  description = "Regionalize the declared proxied hostnames to FedRAMP Moderate Domestic processing locations."
  type        = bool
  default     = false
}

variable "regional_hostnames" {
  description = "Proxied hostnames to regionalize, keyed by a stable Terraform name. Each value requires its owning zone ID and hostname."
  type = map(object({
    zone_id  = string
    hostname = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for entry in values(var.regional_hostnames) :
      can(regex("^[0-9a-f]{32}$", entry.zone_id))
    ])
    error_message = "Each regional hostname zone_id must be a 32-character lowercase hexadecimal zone ID."
  }

  validation {
    condition = alltrue([
      for entry in values(var.regional_hostnames) :
      can(regex("^(?:\\*\\.)?[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])$", entry.hostname))
    ])
    error_message = "Each regional hostname must be a DNS hostname, optionally with a one-label wildcard."
  }
}
