# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  Local Values - Naming, Tags, Computed Values                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

locals {
  # ─── Naming Convention ────────────────────────────────────────────────────
  name_prefix  = "${var.project_name}-${var.environment}"
  cluster_name = "aks-${local.name_prefix}"
  acr_name     = lower(replace("acr${var.project_name}${var.environment}", "-", ""))
  dns_prefix   = "${var.project_name}-${var.environment}"

  # ─── Tags ─────────────────────────────────────────────────────────────────
  tags = {
    project     = var.project_name
    environment = var.environment
    owner       = var.owner
    managed_by  = "terraform"
    lab         = "aks-landing-zone"
  }
}
