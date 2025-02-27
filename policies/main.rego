package spacelift

# Skip runs for documentation and translation changes
skip_run {
    # Get the list of changed files
    files := input.push.changed_files

    # Skip if ALL changes are documentation or translation related
    all([
        is_doc_or_translation(file)
    ]) { file := files[_] }
}

# Helper to identify documentation or translation files
is_doc_or_translation(file) {
    any([
        endswith(file, ".md"),
        contains(file, "README."),
        contains(file, "DOCUMENTATION."),
        contains(input.push.commit_message, "[skip spacelift]"),
        contains(input.push.commit_message, "translation via")
    ])
}

# Allow pushes for any changes that are not documentation/translation
allow_push[msg] {
    # Get the list of changed files
    files := input.push.changed_files

    # Allow if ANY file is not documentation/translation
    not skip_run

    msg := "Changes include non-documentation files"
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