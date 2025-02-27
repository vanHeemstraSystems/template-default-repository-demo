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

# 3. Verify Spacelift credentials
echo "Verifying Spacelift credentials..."
if [ -z "$SPACELIFT_API_KEY_ID" ] || [ -z "$SPACELIFT_API_KEY_SECRET" ]; then
    echo "❌ Error: Spacelift credentials not found!"
    echo "Please set SPACELIFT_API_KEY_ID and SPACELIFT_API_KEY_SECRET"
    exit 1
fi

echo "✅ Cleanup complete! You can now run:"
echo "tofu plan    # to see changes"
echo "tofu apply   # to apply changes"
