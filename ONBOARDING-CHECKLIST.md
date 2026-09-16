# FedRAMP Moderate onboarding checklist

Account: values are supplied through the ignored local `terraform.tfvars` and are deliberately omitted from Git.

Use this checklist with your Cloudflare account team. Store evidence in an approved system; do not place regulated or customer-sensitive material in Git or unapproved support channels.

The target remains an account on Cloudflare's normal public platform. This process applies the controls and entitlements required for Moderate; it does not migrate the account to the separate FedRAMP High environment.

## 1. Account-level entitlements

- [ ] Cloudflare has confirmed entitlements for this exact account ID.
- [ ] Customer Metadata Boundary entitlement is present and configured to retain logs in the US.
- [ ] Data Localization Suite - Regional Services entitlement is present.
- [ ] Advanced Certificate Manager or an approved certificate option is present when proxied TLS hostnames are in scope.
- [ ] Every other contracted service is provisioned.
- [ ] Optional International FedRAMP processing is **not** enabled unless the scenario has been separately reviewed and approved.

Terraform cannot complete Cloudflare-side entitlement steps; coordinate them with the account team.

## 2. Dashboard SSO and FedRAMP warning

- [ ] Customer-approved SSO email domain is documented.
- [ ] Customer IdP connector is configured and tested.
- [ ] SSO connector domain ownership is verified.
- [ ] FedRAMP warning language appears during SSO login.
- [ ] Normal SSO login succeeds.
- [ ] One-time PIN/support break-glass process is documented and tested.
- [ ] SCIM is configured and tested if selected.
- [ ] Impact on users who access multiple Cloudflare accounts with the same email domain is accepted.

Terraform can create the domain connector and force FedRAMP language, but IdP setup, login testing, and emergency procedures remain operator tasks.

## 3. Product-specific controls

### Application Services

- [ ] DNS-only scope, if used, has Customer Metadata Boundary and SSO confirmed.
- [ ] Every proxied DNS/CDN hostname is assigned to Regional Services region `fedramp`.
- [ ] Advanced Certificate Manager or approved custom certificates are used.
- [ ] Geo Key Manager, Spectrum, Tiered Cache, Cache Reserve, Aegis, and BYOIP controls are completed when those products are in scope.

### Zero Trust

- [ ] The Access team domain exists and Cloudflare has confirmed its FedRAMP Moderate Regional Services entitlement.
- [ ] Cloudflare Tunnel uses the approved US region configuration when deployed.
- [ ] Cloudflare has confirmed the required Mesh/Gateway traffic regionalization for the account.
- [ ] Gateway egress IPs, if purchased, are selected from approved FedRAMP locations.
- [ ] CASB FedRAMP entitlement is enabled when CASB is in scope.

### Developer Platform

- [ ] Durable Objects use the `fedramp` jurisdiction when in scope.
- [ ] R2 has its enterprise subscription and FedRAMP entitlement; all regulated buckets use the FedRAMP jurisdiction.
- [ ] Worker custom domains are regionalized to `fedramp`.
- [ ] Stream follows its FedRAMP-specific ingestion restrictions.

- [ ] Each purchased product has been checked against the current Product List in Scope.
- [ ] Each product-specific enablement procedure has an owner and evidence.

## 4. Customer responsibilities

- [ ] The current Customer Responsibilities document has been shared through the approved confidential channel.
- [ ] Customer acknowledges its configuration and operating responsibilities.
- [ ] Support users know not to submit regulated data through unapproved support channels.
- [ ] Approved sensitive-data exchange method is documented.
- [ ] Support/escalation contacts and incident process are documented.

## Final evidence gate

- [ ] `terraform validate` passes.
- [ ] Reviewed `terraform plan` contains only intended resources and no destruction.
- [ ] SSO evidence is attached.
- [ ] Regional processing evidence is attached for every applicable hostname/product.
- [ ] All four sections above are complete before describing the account as FedRAMP Moderate compliant.

## Terraform control-to-evidence register

| Control | Coverage | Required evidence | Current status |
|---|---|---|---|
| Account identity guard | Prevents applying to the wrong account | Plan resolves the account ID and matches `expected_account_name` | Customer verifies before apply |
| Customer Metadata Boundary | US storage of covered customer logs/analytics; no out-of-region access | Live CMB API result: `regions = "us"`, `allow_out_of_region_access = false` | Customer verifies after apply |
| Dashboard SSO connector | Domain-scoped dashboard SSO and FedRAMP warning language | Verified domain plus recorded successful SSO, warning-page, and break-glass tests | Not configured |
| Regional Hostnames | In-region TLS termination and application processing for each declared proxied hostname | State/API and `CF-RAY` evidence per hostname | Evaluate for each customer hostname |
| Product-specific controls | Product-specific data residency and processing beyond CMB/Regional Hostnames | Evidence from each applicable product runbook | Open until product scope is confirmed |
