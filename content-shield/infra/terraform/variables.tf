variable "project_id" {
  description = "GCP project ID where content-shield resources will be created."
  type        = string
}

variable "region" {
  description = "GCP region for resource deployment."
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}
