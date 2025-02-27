package spacelift

# Skip runs for documentation and translation changes
skip_run {
    # Skip based on commit message
    contains(input.push.commit_message, "translation via")
}

skip_run {
    # Skip based on commit author
    input.push.commit_author == "github-actions[bot]"
}

skip_run {
    # Skip based on file patterns
    files := input.push.changed_files
    all([is_doc_or_translation(files[_])])
}

# Helper to identify documentation or translation files
is_doc_or_translation(file) {
    any([
        endswith(file, ".md"),
        contains(file, "README."),
        contains(file, "DOCUMENTATION."),
        contains(file, "translation")
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