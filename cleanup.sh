#!/bin/bash

echo "🧹 Starting cleanup..."

# 1. Clean local OpenTofu files
echo "Cleaning local OpenTofu files..."
rm -f terraform.tfstate*
rm -f .terraform.lock.hcl
rm -rf .terraform/

# 2. Initialize OpenTofu
echo "Initializing OpenTofu..."
tofu init

# 3. Remove from state if exists
echo "Removing resources from state if they exist..."
tofu state rm spacelift_stack.main 2>/dev/null || true
tofu state rm spacelift_context.main 2>/dev/null || true
tofu state rm spacelift_policy.main 2>/dev/null || true
tofu state rm spacelift_context_attachment.main 2>/dev/null || true
tofu state rm spacelift_policy_attachment.main 2>/dev/null || true

# 4. Verify Spacelift credentials
echo "Verifying Spacelift credentials..."
if [ -z "$SPACELIFT_API_KEY_ID" ] || [ -z "$SPACELIFT_API_KEY_SECRET" ]; then
    echo "❌ Error: Spacelift credentials not found!"
    echo "Please set SPACELIFT_API_KEY_ID and SPACELIFT_API_KEY_SECRET"
    exit 1
fi

echo "✅ Cleanup complete! You can now run:"
echo "tofu plan    # to see changes"
echo "tofu apply   # to apply changes"
