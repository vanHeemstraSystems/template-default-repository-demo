terraform {
  required_providers {
    spacelift = {
      source = "spacelift-io/spacelift"
    }
  }
}

# Configure the Spacelift provider with debug logging
provider "spacelift" {}

# Data source to check if stack exists
data "spacelift_stack" "existing" {
  count = can(spacelift_stack.main) ? 0 : 1
  name  = "template-default-repository-demo"
}

# Data source to check if context exists
data "spacelift_context" "existing" {
  count = can(spacelift_context.main) ? 0 : 1
  name  = "template-default-repository-demo-context"
}

# Data source to check if policy exists
data "spacelift_policy" "existing" {
  count = can(spacelift_policy.main) ? 0 : 1
  name  = "template-default-repository-demo-policy"
}

# Output debug information
output "debug_info" {
  value = {
    stack_exists   = length(data.spacelift_stack.existing) > 0
    context_exists = length(data.spacelift_context.existing) > 0
    policy_exists  = length(data.spacelift_policy.existing) > 0
  }
}

# Create the stack with existence check
resource "spacelift_stack" "main" {
  name        = "template-default-repository-demo"
  repository  = "template-default-repository-demo"
  branch      = "main"
  description = "React application deployment stack"

  runner_image = "node:20"
  
  administrative = true
  autodeploy     = true
  
  # Remove worker_pool_id completely as it might be managed by the UI
  # worker_pool_id = "public-worker-pool"

  labels = [
    "react",
    "frontend",
    "github-pages"
  ]

  enable_well_known_secret_masking = true
  terraform_smart_sanitization     = true
  github_action_deploy             = false  # Keep false unless needed

  lifecycle {
    precondition {
      condition     = length(data.spacelift_stack.existing) == 0
      error_message = "Stack already exists"
    }
  }
}

# Create a context with existence check
resource "spacelift_context" "main" {
  name        = "template-default-repository-demo-context"
  description = "Shared configuration for React application"

  lifecycle {
    precondition {
      condition     = length(data.spacelift_context.existing) == 0
      error_message = "Context already exists"
    }
  }
}

# Attach the context to the stack
resource "spacelift_context_attachment" "main" {
  context_id = spacelift_context.main.id
  stack_id   = spacelift_stack.main.id
}

# Create policies with existence check
resource "spacelift_policy" "main" {
  name = "template-default-repository-demo-policy"
  body = file("${path.module}/policies/main.rego")
  type = "PLAN"

  lifecycle {
    precondition {
      condition     = length(data.spacelift_policy.existing) == 0
      error_message = "Policy already exists"
    }
  }
}

# Attach the policy to the stack
resource "spacelift_policy_attachment" "main" {
  policy_id = spacelift_policy.main.id
  stack_id  = spacelift_stack.main.id
}