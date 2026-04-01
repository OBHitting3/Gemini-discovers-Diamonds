terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    prefix = "terraform/state/content-shield"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  service_name = "content-shield"
  labels = {
    app         = local.service_name
    environment = var.environment
    managed_by  = "terraform"
  }
}
