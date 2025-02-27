package spacelift

# First, check if this is a Spacelift-related change
is_spacelift_file(file) {
    any([
        endswith(file, "main.tf"),
        startswith(file, ".spacelift/"),
        startswith(file, "policies/")
    ])
}

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

# Allow pushes ONLY for Spacelift-related changes
allow[msg] {
    # Get the list of changed files
    files := input.push.changed_files

    # Allow if ANY file is Spacelift-related
    any([is_spacelift_file(files[_])])

    # And ensure we're not skipping this run
    not skip_run

    msg := "Changes include Spacelift-managed files"
}

# Block all other changes
deny[msg] {
    not allow
    msg := "Only Spacelift-related changes are allowed"
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