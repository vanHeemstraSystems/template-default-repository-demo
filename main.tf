terraform {
  required_providers {
    spacelift = {
      source = "spacelift-io/spacelift"
    }
  }
}

# Configure the Spacelift provider
provider "spacelift" {}

# Use data sources for existing resources
data "spacelift_stack" "main" {
  name = "template-default-repository-demo"
}

data "spacelift_context" "main" {
  name = "template-default-repository-demo-context"
}

data "spacelift_policy" "main" {
  name = "template-default-repository-demo-policy"
}

# Use data sources for attachments
resource "spacelift_context_attachment" "main" {
  context_id = data.spacelift_context.main.id
  stack_id   = data.spacelift_stack.main.id
}

resource "spacelift_policy_attachment" "main" {
  policy_id = data.spacelift_policy.main.id
  stack_id  = data.spacelift_stack.main.id
}