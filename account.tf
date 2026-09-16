data "cloudflare_account" "target" {
  account_id = var.cloudflare_account_id
}

resource "terraform_data" "account_guard" {
  input = {
    account_id   = data.cloudflare_account.target.id
    account_name = data.cloudflare_account.target.name
  }

  lifecycle {
    precondition {
      condition     = data.cloudflare_account.target.name == var.expected_account_name
      error_message = "Account safety check failed: the supplied account ID is not ${var.expected_account_name}."
    }
  }
}

resource "terraform_data" "customer_metadata_boundary" {
  count = var.enable_customer_metadata_boundary ? 1 : 0

  triggers_replace = [
    var.cloudflare_account_id,
    var.customer_metadata_boundary_region,
    var.customer_metadata_boundary_allow_out_of_region_access,
    plantimestamp(),
  ]

  depends_on = [terraform_data.account_guard]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      url="https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/logs/control/cmb/config"
      auth_header="Authorization: Bearer $CLOUDFLARE_API_TOKEN"

      get_cmb() {
        curl --fail-with-body --silent --show-error \
          --header "$auth_header" \
          "$url"
      }

      current="$(get_cmb)"
      current_region="$(jq -r '.result.regions // .result.region // "global" | if type == "array" then .[0] else . end' <<<"$current")"
      current_out_of_region="$(jq -r '.result.allow_out_of_region_access // false' <<<"$current")"

      if [[ "$current_region" != "$CMB_REGION" || "$current_out_of_region" != "$CMB_ALLOW_OUT_OF_REGION_ACCESS" ]]; then
        payload="$(jq -cn \
          --arg regions "$CMB_REGION" \
          --argjson allow "$CMB_ALLOW_OUT_OF_REGION_ACCESS" \
          '{regions: $regions, allow_out_of_region_access: $allow}')"

        curl --fail-with-body --silent --show-error \
          --request POST \
          --header "$auth_header" \
          --header "Content-Type: application/json" \
          --data "$payload" \
          "$url" >/dev/null
      fi

      for attempt in 1 2 3 4 5 6; do
        observed="$(get_cmb)"
        observed_region="$(jq -r '.result.regions // .result.region // "global" | if type == "array" then .[0] else . end' <<<"$observed")"
        observed_out_of_region="$(jq -r '.result.allow_out_of_region_access // false' <<<"$observed")"

        if [[ "$observed_region" == "$CMB_REGION" && "$observed_out_of_region" == "$CMB_ALLOW_OUT_OF_REGION_ACCESS" ]]; then
          jq -cn \
            --arg region "$observed_region" \
            --argjson allow "$observed_out_of_region" \
            '{customer_metadata_boundary: $region, allow_out_of_region_access: $allow, verified: true}'
          exit 0
        fi

        [[ "$attempt" == "6" ]] || sleep 5
      done

      echo "Customer Metadata Boundary did not converge to the requested settings" >&2
      exit 1
    EOT

    environment = {
      CLOUDFLARE_API_TOKEN           = var.cloudflare_api_token
      CLOUDFLARE_ACCOUNT_ID          = var.cloudflare_account_id
      CMB_REGION                     = var.customer_metadata_boundary_region
      CMB_ALLOW_OUT_OF_REGION_ACCESS = tostring(var.customer_metadata_boundary_allow_out_of_region_access)
    }
  }
}
