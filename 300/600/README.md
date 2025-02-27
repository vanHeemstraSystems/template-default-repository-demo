# 600 - Deploy to Spacelift

```
Step-by-step procedure:

Prerequisites Check:
[ ] GitHub repository exists
[ ] main.tf is in repository
[ ] policies/main.rego exists
[ ] .terraform.lock.hcl is committed
[ ] Spacelift API credentials are available

Local Environment Setup:
[ ] Run cleanup.sh to:
    - Clean local files
    - Initialize OpenTofu
    - Remove state entries
    - Verify credentials

Spacelift UI Cleanup:
[ ] Delete stack (choose "Keep resources")
[ ] Delete context
[ ] Delete policy
[ ] Cancel any blocking runs

Resource Management:
[ ] Apply updated main.tf with data sources
[ ] Verify in Spacelift UI

Stack Configuration:
[ ] Add environment variables
[ ] Verify context attachment
[ ] Verify policy attachment
```

Set up Spacelift for our application. 

First, let's create a Spacelift configuration. 

We'll need to create a few files:

1. First, let's create a Spacelift stack configuration file (```stack.yml```) in the root of the repository:

```
stack:
  name: template-default-repository-demo
  description: React application deployment stack
  repository: template-default-repository-demo
  branch: main
  administrative: true
  autodeploy: true
  worker_pool: "public-worker-pool"

  # Define the runner image
  runner_image: node:20

  # Define before_init commands
  before_init:
    - npm install -g nx@latest

  # Define before_apply commands
  before_apply:
    - npm ci
    - npx nx build hatch_project --configuration=production

  # Define the deployment commands
  apply:
    - echo "Deploying to production..."
    # Add your deployment commands here

  # Define environment variables
  environment:
    - name: NODE_ENV
      value: production
    - name: PUBLIC_URL
      value: /template-default-repository-demo
```
repository-name/stack.yml

**Note**: To find your correct worker pool ID:
- Go to Spacelift dashboard
- Click on "Worker Pools" in the left menu
- Note the ID of the available worker pool (e.g. ```public-worker-pool```)
- Use that ID in both configuration files (```stack.yml```)

2. Let's create a policy file for Spacelift (```main.rego```) inside the ```policies``` directory at the root of the repository:

```
package spacelift

# Skip ALL manual triggers if there are pending translation commits
skip_run {
    # Skip if ANY recent commit is a translation
    any([
        contains(input.push.commit_message, "translation via"),
        input.push.commit_author == "github-actions[bot]"
    ])
}

# First, check if this is a Spacelift-related change
is_spacelift_file(file) {
    any([
        endswith(file, "main.tf"),
        startswith(file, ".spacelift/"),
        startswith(file, "policies/"),
        endswith(file, "main.rego")
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

    msg := sprintf("Changes include Spacelift-managed files: %v", [files])
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
```
repository-name/policies/main.rego

3. Let's create a Terraform configuration to manage Spacelift resources (```main.tf```) at the root of the repository:

```
terraform {
  required_providers {
    spacelift = {
      source = "spacelift-io/spacelift"
    }
  }
}

# Configure the Spacelift provider
provider "spacelift" {
  api_key_endpoint = var.spacelift_api_key_endpoint
  api_key_id      = var.spacelift_api_key_id
  api_key_secret  = var.spacelift_api_key_secret
}

# Debug outputs (without current_stack)
output "debug_info" {
  value = {
    api_endpoint  = coalesce(var.spacelift_api_key_endpoint, "default")
    workspace     = coalesce(var.spacelift_workspace_root, "default")
  }
}

# Add variables for debugging
variable "spacelift_api_key_endpoint" {
  type = string
}

variable "spacelift_api_key_id" {
  type = string
}

variable "spacelift_api_key_secret" {
  type      = string
  sensitive = true
}

variable "spacelift_workspace_root" {
  type    = string
  default = null
}

# Create resources (not data sources)
resource "spacelift_stack" "main" {
  name        = "template-default-repository-demo-spacelift"
  repository  = "template-default-repository-demo"
  branch      = "main"
  description = "React application deployment stack (Spacelift managed)"

  runner_image = "node:20"
  
  administrative = true
  autodeploy     = true

  labels = [
    "react",
    "frontend",
    "github-pages",
    "spacelift-managed"
  ]

  # Add path setting and recursive flag
  project_root = "."
  manage_state = true
  
  # Enable local preview
  enable_local_preview = true
}

resource "spacelift_context" "main" {
  name        = "template-default-repository-demo-context-spacelift"
  description = "Shared configuration for React application (Spacelift managed)"
}

resource "spacelift_policy" "main" {
  name        = "template-default-repository-demo-policy-spacelift-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  description = "Shared configuration for React application (Spacelift managed)"
  body        = file("${path.module}/policies/main.rego")
  type        = "PLAN"
}

resource "spacelift_context_attachment" "main" {
  context_id = spacelift_context.main.id
  stack_id   = spacelift_stack.main.id
}

resource "spacelift_policy_attachment" "main" {
  policy_id = spacelift_policy.main.id
  stack_id  = spacelift_stack.main.id
}
```
repository-name/main.tf

4. Add a .spacelift/config.yml file to your repository at the root:

```
$ cd / # Go to the root of the repository
$ mkdir .spacelift
$ cd .spacelift
$ touch config.yml
```

The content of this file (```config.yml```):

```
version: 1

workspace_configs:
  - name: template-default-repository-demo-spacelift
    terraform_version: "1.5.0"
    autoformat: true
    autodeploy: true
    
    # Add project root and workspace settings
    project_root: "."
    workspace: "default"
    
    # Add environment settings
    environment:
      - TF_CLI_ARGS_init: "-backend=false"
      - TF_IN_AUTOMATION: "true"
      - TF_WORKSPACE: "default"
    
    # Define the build and deployment process
    before_init:
      - npm install -g nx@latest
    
    before_apply:
      - npm ci
      - npx nx build hatch_project --configuration=production
    
    # Define the deployment process
    deployment:
      steps:
        - name: Deploy to GitHub Pages
          run: |
            REPO_NAME=$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f2)
            
            # Update asset paths
            sed -i "s|<base href=\"/\"|<base href=\"/$REPO_NAME/\"|g" dist/apps/hatch_project/index.html
            sed -i "s|src=\"/assets|src=\"/$REPO_NAME/assets|g" dist/apps/hatch_project/index.html
            sed -i "s|href=\"/assets|href=\"/$REPO_NAME/assets|g" dist/apps/hatch_project/index.html
            
            # Deploy using GitHub Pages action
            uses: peaceiris/actions-gh-pages@v3
            with:
              github_token: ${{ secrets.GITHUB_TOKEN }}
              publish_dir: ./dist/apps/hatch_project
```
./spacelift/config.yml

To set this up:

1. Create a [Spacelift](https://spacelift.io) account and connect it to your GitHub repository.

- Go to [Spacelift](https://spacelift.io)
- Sign up for an account: Click "Sign Up" or "Get Started". We have account [vanheemstrasystems.app.spacelift.io](https://vanheemstrasystems.app.spacelift.io/dashboard). Choose GitHub as your authentication method.
- Connect it to your GitHub repository (e.g., template-default-repository-demo): After logging in, click "Create Stack" button in the [dashboard](https://vanheemstrasystems.app.spacelift.io/dashboard). 
For Stack Details use name: ```template-default-repository-demo```, Space: ```root```, Labels: "react", "frontend", "github-pages", "spacelift-managed", Description: ```Template Default Repository Demo```. 

Click **Continue**. 

Select GitHub as your VCS provider. 

Choose the ```vanHeemstraSystems/template-default-repository-demo``` repository. 

Choose Branch: ```main```. 

Set Project root to "." (it is optional, but we want to set it to root). 

Add these Additional project globs:
```
main.tf
policies/**
.spacelift/**
```

Click **Continue**. 

- Choose vendor:

For your React application deployment, since we have a ```main.tf``` file that uses the Spacelift Terraform provider, you should choose:

- OpenTofu / Terraform

This is the appropriate choice because, your ```main.tf``` file is written in Terraform/OpenTofu syntax. We're using the spacelift Terraform provider in the configuration. We need to manage Spacelift resources (stack, context, policies) using Infrastructure as Code

- Workflowtool: OpenTofu

- OpenTofu version: 1.9.0 (pick the latest)

- Smart Sanitization (recommended): Yes

- Manage State (recommended): Yes

- External state access: No

- Import existing state file: No

Click **Create & Continue**.

- Stack created: Now you can make it even more powerful by adding hooks, attaching cloud, policies or contexts in the next steps!

Click **Continue**.

- Define behavior (optional): Define additional stack settings

Of all choices, make sure to set **Administrative**, **Autodeploy** and **Enable secrets masking** to Yes. Leave all others at their default setting.

Click **Continue**.

- Add hooks (optional)

Click **Continue**.

- Attach cloud integration (optional)

Click **Continue**.

- Attach policies (optional)

Click **Continue**.

- Attach contexts (optional)

Click **Continue**.

- Summary

Click **Confirm**.

Grant the requested permissions to Spacelift.

We need to configure the Spacelift provider with credentials. You'll need:

- Get your Spacelift API credentials:
<br/>- Go to your Spacelift dashboard
<br/>- Click on your profile icon (top right)
<br/>- Select "API Keys"
<br/>- Create a new API key if you don't have one

---------- START: Optional --------------

# Enable DEBUG level logging
export TF_LOG=DEBUG

# Set log file path
export TF_LOG_PATH=./terraform.log

# Verify the environment variables are set
echo "TF_LOG=$TF_LOG"
echo "TF_LOG_PATH=$TF_LOG_PATH"

---------- END: Optional ----------------

Configure GitHub Pages:
- Go to repository settings
- Enable GitHub Pages
- Set branch to gh-pages
- Set folder to / (root)

Now run the ```cleanup.sh``` script locally to ensure there are no outdated settings or residu of previous rounds.

```
$ chmod +x cleanup.sh # Optional, to make the script executionable
$ ./cleanup.sh
```

You will see something like below:

```
🧹 Starting cleanup...
Cleaning local OpenTofu files...
Initializing OpenTofu...

Initializing the backend...

Initializing provider plugins...
- Finding latest version of spacelift-io/spacelift...
- Installing spacelift-io/spacelift v1.20.0...
[WARN] Provider spacelift-io/spacelift (registry.opentofu.org) gpg key expired, this will fail in future versions of OpenTofu
- Installed spacelift-io/spacelift v1.20.0 (signed, key ID E302FB5AA29D88F7)

Providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://opentofu.org/docs/cli/plugins/signing/

OpenTofu has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that OpenTofu can guarantee to make the same selections by default when
you run "tofu init" in the future.

OpenTofu has been successfully initialized!

You may now begin working with OpenTofu. Try running "tofu plan" to see
any changes that are required for your infrastructure. All OpenTofu commands
should now work.

If you ever set or change modules or backend configuration for OpenTofu,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
Removing resources from state if they exist...
Verifying Spacelift credentials...
✅ Cleanup complete! You can now run:
tofu plan    # to see changes
tofu apply   # to apply changes
```

Now let's import the existing resources:

A. First, import the stack:

```
$ tofu import spacelift_stack.main template-default-repository-demo
```

You will be prompted as follows:

```
spacelift_stack.main: Importing from ID "template-default-repository-demo"...
spacelift_stack.main: Import prepared!
  Prepared spacelift_stack for import
spacelift_stack.main: Refreshing state... [id=template-default-repository-demo]

Import successful!

The resources that were imported are shown above. These resources are now in
your OpenTofu state and will henceforth be managed by OpenTofu.
```

B. Now let's import the context:

```
$ tofu import spacelift_context.main template-default-repository-demo-context
```

Its prompt is:

```
spacelift_context.main: Importing from ID "template-default-repository-demo-context"...
spacelift_context.main: Import prepared!
  Prepared spacelift_context for import
spacelift_context.main: Refreshing state... [id=template-default-repository-demo-context]

Import successful!

The resources that were imported are shown above. These resources are now in
your OpenTofu state and will henceforth be managed by OpenTofu.
```

C. Now let's import the policy:

```
$ tofu import spacelift_policy.main template-default-repository-demo-policy
```

And again a prompt:

```
spacelift_policy.main: Importing from ID "template-default-repository-demo-policy"...
spacelift_policy.main: Import prepared!
  Prepared spacelift_policy for import
spacelift_policy.main: Refreshing state... [id=template-default-repository-demo-policy]

Import successful!

The resources that were imported are shown above. These resources are now in
your OpenTofu state and will henceforth be managed by OpenTofu.
```

D. Now let's import the context attachment:

```
$ tofu import spacelift_context_attachment.main "template-default-repository-demo-context/template-default-repository-demo"
```

You'll be prompted so:

```
spacelift_context_attachment.main: Importing from ID "template-default-repository-demo-context/template-default-repository-demo"...
spacelift_context_attachment.main: Import prepared!
  Prepared spacelift_context_attachment for import
spacelift_context_attachment.main: Refreshing state... [id=template-default-repository-demo-context/01JN39S1PY8AD6EQWV2WE9AD7B]

Import successful!

The resources that were imported are shown above. These resources are now in
your OpenTofu state and will henceforth be managed by OpenTofu.
```

E. Now let's import the final piece - the policy attachment:

```
$ tofu import spacelift_policy_attachment.main "template-default-repository-demo-policy/template-default-repository-demo"
```

With as a result:

```
spacelift_policy_attachment.main: Importing from ID "template-default-repository-demo-policy/template-default-repository-demo"...
spacelift_policy_attachment.main: Import prepared!
  Prepared spacelift_policy_attachment for import
spacelift_policy_attachment.main: Refreshing state... [id=template-default-repository-demo-policy/01JN39S1PMJ6QDA0ZKWBSCEZBP]

Import successful!

The resources that were imported are shown above. These resources are now in
your OpenTofu state and will henceforth be managed by OpenTofu.
```

Now lets run a plan to see what our debug output shows:

```
$ tofu plan -var-file="terraform.tfvars"
```

You will be prompted somewhat like this:

```
OpenTofu used the selected providers to generate the following execution plan. Resource
actions are indicated with the following symbols:
  + create

OpenTofu will perform the following actions:

  # spacelift_context.main will be created
  + resource "spacelift_context" "main" {
      + description = "Shared configuration for React application (Spacelift managed)"
      + id          = (known after apply)
      + name        = "template-default-repository-demo-context-spacelift"
      + space_id    = (known after apply)
    }

  # spacelift_context_attachment.main will be created
  + resource "spacelift_context_attachment" "main" {
      + context_id = (known after apply)
      + id         = (known after apply)
      + priority   = 0
      + stack_id   = (known after apply)
    }

  # spacelift_policy.main will be created
  + resource "spacelift_policy" "main" {
      + body     = <<-EOT
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
        EOT
      + id       = (known after apply)
      + name     = "template-default-repository-demo-policy-spacelift"
      + space_id = (known after apply)
      + type     = "PLAN"
    }

  # spacelift_policy_attachment.main will be created
  + resource "spacelift_policy_attachment" "main" {
      + id        = (known after apply)
      + policy_id = (known after apply)
      + stack_id  = (known after apply)
    }

  # spacelift_stack.main will be created
  + resource "spacelift_stack" "main" {
      + administrative                   = true
      + autodeploy                       = true
      + autoretry                        = false
      + aws_assume_role_policy_statement = (known after apply)
      + branch                           = "main"
      + description                      = "React application deployment stack (Spacelift managed)"
      + enable_local_preview             = false
      + enable_well_known_secret_masking = false
      + github_action_deploy             = true
      + id                               = (known after apply)
      + labels                           = [
          + "frontend",
          + "github-pages",
          + "react",
          + "spacelift-managed",
        ]
      + manage_state                     = true
      + name                             = "template-default-repository-demo-spacelift"
      + protect_from_deletion            = false
      + repository                       = "template-default-repository-demo"
      + runner_image                     = "node:20"
      + slug                             = (known after apply)
      + space_id                         = (known after apply)
      + terraform_external_state_access  = false
      + terraform_smart_sanitization     = false
      + terraform_workflow_tool          = (known after apply)
    }

Plan: 5 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + debug_info = {
      + api_endpoint = "default"
      + workspace    = "default"
    }

──────────────────────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so OpenTofu can't guarantee to take
exactly these actions if you run "tofu apply" now.
```

Now lets apply the plan to see what our debug output shows:

```
$ tofu apply -var-file="terraform.tfvars"
```

When prompted, type ```yes``` to confirm.

And here is the feedback:

```
OpenTofu used the selected providers to generate the following execution plan. Resource
actions are indicated with the following symbols:
  + create

OpenTofu will perform the following actions:

  # spacelift_context.main will be created
  + resource "spacelift_context" "main" {
      + description = "Shared configuration for React application (Spacelift managed)"
      + id          = (known after apply)
      + name        = "template-default-repository-demo-context-spacelift"
      + space_id    = (known after apply)
    }

  # spacelift_context_attachment.main will be created
  + resource "spacelift_context_attachment" "main" {
      + context_id = (known after apply)
      + id         = (known after apply)
      + priority   = 0
      + stack_id   = (known after apply)
    }

  # spacelift_policy.main will be created
  + resource "spacelift_policy" "main" {
      + body     = <<-EOT
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
        EOT
      + id       = (known after apply)
      + name     = "template-default-repository-demo-policy-spacelift"
      + space_id = (known after apply)
      + type     = "PLAN"
    }

  # spacelift_policy_attachment.main will be created
  + resource "spacelift_policy_attachment" "main" {
      + id        = (known after apply)
      + policy_id = (known after apply)
      + stack_id  = (known after apply)
    }

  # spacelift_stack.main will be created
  + resource "spacelift_stack" "main" {
      + administrative                   = true
      + autodeploy                       = true
      + autoretry                        = false
      + aws_assume_role_policy_statement = (known after apply)
      + branch                           = "main"
      + description                      = "React application deployment stack (Spacelift managed)"
      + enable_local_preview             = false
      + enable_well_known_secret_masking = false
      + github_action_deploy             = true
      + id                               = (known after apply)
      + labels                           = [
          + "frontend",
          + "github-pages",
          + "react",
          + "spacelift-managed",
        ]
      + manage_state                     = true
      + name                             = "template-default-repository-demo-spacelift"
      + protect_from_deletion            = false
      + repository                       = "template-default-repository-demo"
      + runner_image                     = "node:20"
      + slug                             = (known after apply)
      + space_id                         = (known after apply)
      + terraform_external_state_access  = false
      + terraform_smart_sanitization     = false
      + terraform_workflow_tool          = (known after apply)
    }

Plan: 5 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + debug_info = {
      + api_endpoint = "default"
      + workspace    = "default"
    }

Do you want to perform these actions?
  OpenTofu will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

spacelift_policy.main: Creating...
spacelift_context.main: Creating...
spacelift_stack.main: Creating...
spacelift_policy.main: Creation complete after 0s [id=template-default-repository-demo-policy-spacelift]
spacelift_context.main: Creation complete after 0s [id=template-default-repository-demo-context-spacelift]
spacelift_stack.main: Creation complete after 1s [id=template-default-repository-demo-spacelift]
spacelift_policy_attachment.main: Creating...
spacelift_context_attachment.main: Creating...
spacelift_policy_attachment.main: Creation complete after 0s [id=template-default-repository-demo-policy-spacelift/01JN3MHGERDSWQ9BHTCCGTNX0K]
spacelift_context_attachment.main: Creation complete after 1s [id=template-default-repository-demo-context-spacelift/01JN3MHGFYZTDBQ2964DNNS4JV]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

debug_info = {
  "api_endpoint" = "default"
  "workspace" = "default"
}
```

Next steps:

- Go to Spacelift UI
- From "Stacks" choose "template-default-repository-demo"
- Add the environment variables to the stack (Case-sensitive !!):
<br/>NODE_ENV=production
<br/>PUBLIC_URL=/template-default-repository-demo
<br/>TF_VAR_spacelift_api_key_endpoint=https://vanheemstrasystems.app.spacelift.io
<br/>TF_VAR_spacelift_api_key_id=01JMMMBYVHKJP25KE6QHVXM2PY
<br/>TF_VAR_spacelift_api_key_secret=[your-secret-value] (mark as sensitive)

For the blocking runs, we can:

I. Cancel any pending runs:
- Go to your stack
- Find any "Blocked" or "Pending" runs
- Click on each run
- Click "Cancel" button

II. Or retry failed runs:
- Go to blocked/failed runs
- Click "Retry" if available
- Or click "Discard" if the run is no longer needed

This will help clear the queue and allow new runs to proceed.

- **IMPORTANT**: Click **Trigger** for the ```template-default-repository-demo``` to force a lookup of the repository on GitHub.

3. Configure Spacelift to use these files.

- Spacelift will detect your stack.yml file.

- Confirm the configuration:
<br/>- Stack name: template-default-repository-demo
<br/>- Branch: main
<br/>- Runner image: node:20
<br/>- Administrative: false
<br/>- Autodeploy: true

4. Configure GitHub permissions for Spacelift.

- Spacelift will request access to your repository
- Accept the permissions for reading code and writing deployments

5. Create your first stack in Spacelift:

- The stack will be automatically configured using your ```stack.yml```.
- It will use the policies defined in ```main.rego```.
- The Terraform configuration in ```main.tf``` will manage your Spacelift resources
- The deployment process will follow ```.spacelift/config.yml```.

Now that the stack is created, let's trigger a run to create the context and policy:
1. Go to the stack
2. Go to Stack Settings > Environment
- Add these variables (Case-sensitive !!):
<br/>NODE_ENV=production
<br/>PUBLIC_URL=/template-default-repository-demo
<br/>TF_VAR_spacelift_api_key_endpoint=https://vanheemstrasystems.app.spacelift.io
<br/>TF_VAR_spacelift_api_key_id=01JMMMBYVHKJP25KE6QHVXM2PY
<br/>TF_VAR_spacelift_api_key_secret=[your-secret-value] (mark as sensitive)
<br/>Mark as Sensitive:
<br/>SPACELIFT_API_KEY_SECRET should be marked as sensitive
2. Click "Trigger"

This should:
- Create the context (template-default-repository-demo-context)
- Create the policy (template-default-repository-demo-policy)
- Attach both to the stack
- The environment variables are ready, so the deployment process should work correctly.

The run will use our main.tf configuration to set everything up.

**NOTE**: If you see Blocked by ######################.

This means we need to approve the run first. The run is blocked because:
1. Policy Check: The run needs administrative approval
2. Run ID: 01JMRXG67G9ARXZXZ6NGKVQJ78

To approve:
1. Click on the run
2. Look for the "Approve" button
3. Click "Approve" to allow the run to proceed

This is a security feature to ensure changes are reviewed before being applied.

To check if Spacelift has detected your configuration files:

5.1. Go to your stack dashboard in Spacelift (template-default-repository-demo)
5.2. Look for the "Source Code" tab or section in your stack's navigation menu
5.3. Click on it to see the detected configuration files. You should see:
- stack.yml
- main.tf
- main.rego
- .spacelift/config.yml
5.4. You can also check the "Settings" tab, which should reflect the configurations from these files

If you don't see these files or their configurations aren't being applied, you might need to:

5.5. Verify the files are in the correct locations in your repository
5.6. Check if Spacelift has the proper permissions to access these files
5.7. Trigger a refresh of your stack configuration

6. Set up any necessary environment variables in Spacelift.

6.1. Go to your stack dashboard in Spacelift (template-default-repository-demo)
6.2. Look for the "Environment" tab or section in your stack's navigation menu
6.3. If not already present, create the following new Environment variables (use ```Plain```, or ```Secret```for confidential values):

- NODE_ENV=production
- PUBLIC_URL=/template-default-repository-demo
- Any other environment-specific variables

7. Set up policies.

- Spacelift will use your ```main.rego``` file.
- This configures:
<br/>- Push permissions to main branch
<br/>- Pull request review requirements
<br/>- Production deployment rules
<br/>- Admin access controls

8. Initialize Terraform.

- Your ```main.tf``` will create:
<br/>- The Spacelift stack
<br/>- A shared configuration context
<br/>- Policy attachments
- Spacelift will automatically manage the state

9. Configure deployment.

- The ```.spacelift/config.yml``` defines:
<br/>- Terraform version: 1.5.0
<br/>- Autoformatting: enabled
<br/>- Autodeployment: enabled
<br/>- Build and deployment steps