resource "cloudflare_sso_connector" "fedramp" {
  for_each = var.enable_sso_connectors ? var.sso_connectors : {}

  depends_on = [terraform_data.account_guard]

  account_id           = var.cloudflare_account_id
  email_domain         = lower(each.value.email_domain)
  enabled              = each.value.enabled
  begin_verification   = each.value.begin_verification
  use_fedramp_language = true
}
