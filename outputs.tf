output "account" {
  description = "Verified target account."
  value = {
    id   = data.cloudflare_account.target.id
    name = data.cloudflare_account.target.name
    type = data.cloudflare_account.target.type
  }
}

output "fedramp_moderate_onboarding_status" {
  description = "Operator-facing status for the FedRAMP Moderate account settings managed by this module."
  value = {
    compliance_status = "ACCOUNT SETTINGS ONLY - NOT A COMPLIANCE CERTIFICATION"

    target_account = {
      verified = data.cloudflare_account.target.name == var.expected_account_name
      id       = data.cloudflare_account.target.id
      name     = data.cloudflare_account.target.name
      type     = data.cloudflare_account.target.type
    }

    customer_metadata_boundary = {
      enabled                    = var.enable_customer_metadata_boundary
      region                     = var.enable_customer_metadata_boundary ? var.customer_metadata_boundary_region : "global"
      allow_out_of_region_access = var.customer_metadata_boundary_allow_out_of_region_access
      managed_resource_present   = length(terraform_data.customer_metadata_boundary) == 1
      purpose                    = "Keep customer logs and analytics metadata in the United States"
    }

    application_processing = {
      regional_services_region_key         = "fedramp"
      regional_hostname_management_enabled = var.enable_regional_hostnames
      managed_regional_hostnames           = length(cloudflare_regional_hostname.fedramp_domestic)
      note                                 = "Regionalize each applicable proxied hostname when zones are added"
    }

    dashboard_sso = {
      management_enabled     = var.enable_sso_connectors
      managed_connectors     = length(cloudflare_sso_connector.fedramp)
      fedramp_warning_forced = var.enable_sso_connectors && length(var.sso_connectors) > 0
    }

    remaining_operator_work = [
      "Configure and test dashboard SSO/IdP and break-glass access",
      "Apply product-specific FedRAMP Moderate regionalization as products and zones are added",
      "Deliver and record acceptance of Customer Responsibilities",
    ]
  }
}

output "sso_connectors" {
  description = "Created SSO connector IDs and domain-verification state."
  value = {
    for key, connector in cloudflare_sso_connector.fedramp : key => {
      id                  = connector.id
      email_domain        = connector.email_domain
      verification_status = connector.verification.status
      verification_code   = connector.verification.code
    }
  }
  sensitive = true
}

output "regional_hostnames" {
  description = "Hostnames configured for FedRAMP Moderate Domestic processing."
  value = {
    for key, hostname in cloudflare_regional_hostname.fedramp_domestic : key => {
      hostname   = hostname.hostname
      region_key = hostname.region_key
      zone_id    = hostname.zone_id
    }
  }
}
