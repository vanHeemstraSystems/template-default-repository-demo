package spacelift

# Allow all pushes to main branch
allow_push[msg] {
    input.push.ref == "refs/heads/main"
    msg := "Allowing push to main branch"
}

# Require pull request reviews
require_review {
    input.pull_request.reviews_count < 1
}

# Define deployment environments
deployment_environment(stack) = "production" {
    stack.branch == "main"
}

# Define access controls
allow_access[msg] {
    input.user.role == "admin"
    msg := "Admin access granted"
}