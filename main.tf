terraform {
  required_providers {
    spacelift = {
      source = "spacelift-io/spacelift"
    }
  }
}

# Configure the Spacelift provider
provider "spacelift" {}

# Debug outputs (without current_stack)
output "debug_info" {
  value = {
    api_endpoint  = coalesce(var.spacelift_api_endpoint, "default")
    workspace     = coalesce(var.spacelift_workspace_root, "default")
  }
}

# Add variables for debugging
variable "spacelift_api_endpoint" {
  type    = string
  default = null
}

variable "spacelift_workspace_root" {
  type    = string
  default = null
}

# Use data sources instead of creating resources
data "spacelift_stack" "main" {
  name = "template-default-repository-demo-spacelift"
}

data "spacelift_context" "main" {
  name = "template-default-repository-demo-context-spacelift"
}

data "spacelift_policy" "main" {
  name = "template-default-repository-demo-policy-spacelift"
}

# Only manage attachments
resource "spacelift_context_attachment" "main" {
  context_id = data.spacelift_context.main.id
  stack_id   = data.spacelift_stack.main.id
}

resource "spacelift_policy_attachment" "main" {
  policy_id = data.spacelift_policy.main.id
  stack_id  = data.spacelift_stack.main.id
}