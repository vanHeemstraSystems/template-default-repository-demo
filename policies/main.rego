package spacelift

# Allow pushes only for specific file changes
allow_push[msg] {
    # Get the list of changed files
    files := input.push.changed_files

    # Check if any of the changed files match our patterns
    any([
        startswith(file, "main.tf"),
        startswith(file, ".spacelift/"),
        startswith(file, "policies/")
    ]) { file := files[_] }

    msg := "Changes affect Spacelift-managed files"
}

# Skip runs for documentation changes
skip_run {
    files := input.push.changed_files
    all([
        file_is_doc(file)
    ]) { file := files[_] }
}

# Helper to identify documentation files
file_is_doc(file) {
    endswith(file, ".md")
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