resource "cloudflare_regional_hostname" "fedramp_domestic" {
  for_each = var.enable_regional_hostnames ? var.regional_hostnames : {}

  depends_on = [terraform_data.account_guard]

  zone_id    = each.value.zone_id
  hostname   = lower(each.value.hostname)
  region_key = "fedramp"
}
