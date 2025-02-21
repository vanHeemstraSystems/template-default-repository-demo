terraform {
  required_providers {
    spacelift = {
      source = "spacelift-io/spacelift"
    }
  }
}

# Configure the Spacelift provider
provider "spacelift" {
  # Configuration options will be provided by Spacelift
}

# Create the stack
resource "spacelift_stack" "main" {
  name        = "template-default-repository-demo"
  repository  = "template-default-repository-demo"
  branch      = "main"
  description = "React application deployment stack"

  runner_image = "node:20"
  
  administrative = true
  autodeploy     = true
  
  worker_pool_id = "default"

  labels = [
    "react",
    "frontend",
    "github-pages"
  ]
}

# Create a context for shared configuration
resource "spacelift_context" "main" {
  name        = "template-default-repository-demo-context"
  description = "Shared configuration for React application"
}

# Attach the context to the stack
resource "spacelift_context_attachment" "main" {
  context_id = spacelift_context.main.id
  stack_id   = spacelift_stack.main.id
}

# Create policies
resource "spacelift_policy" "main" {
  name = "template-default-repository-demo-policy"
  body = file("${path.module}/policies/main.rego")
  type = "PLAN"
}

# Attach the policy to the stack
resource "spacelift_policy_attachment" "main" {
  policy_id = spacelift_policy.main.id
  stack_id  = spacelift_stack.main.id
}