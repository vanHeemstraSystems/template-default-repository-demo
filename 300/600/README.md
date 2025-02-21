# 600 - Deploy to Spacelift

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
  administrative: false
  autodeploy: true
  worker_pool: default

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

2. Let's create a policy file for Spacelift (```main.rego```) at the root of the repository:

```
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
```
repository-name/main.rego

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
  # Configuration options will be provided by Spacelift
}

# Create the stack
resource "spacelift_stack" "main" {
  name        = "template-default-repository-demo"
  repository  = "template-default-repository-demo"
  branch      = "main"
  description = "React application deployment stack"

  runner_image = "node:20"
  
  administrative = false
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
  - name: template-default-repository-demo
    terraform_version: "1.5.0"
    autoformat: true
    autodeploy: true
    
    # Define the deployment process
    deployment:
      steps:
        - name: Install dependencies
          run: npm ci
          
        - name: Build application
          run: npx nx build hatch_project --configuration=production
          
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
- Connect it to your GitHub repository (e.g., template-default-repository-demo): After logging in, click "Create Stack" button in the [dashboard](https://vanheemstrasystems.app.spacelift.io/dashboard). For Stack Details use name: ```template-default-repository-demo```, Space: ```root```, Labels: leave blank for now, Description: ```Template Default repository Demo```. Click **Continue**. Select GitHub as your VCS provider. Choose the ```vanHeemstraSystems/template-default-repository-demo``` repository. Choose Branch: ```main```. Leave Project root empty (it is optional and it will take the default). Click **Continue**. 

- Choose vendor:

For your React application deployment, since we have a ```main.tf``` file that uses the Spacelift Terraform provider, you should choose:

- OpenTofu / Terraform

This is the appropriate choice because, your main.tf file is written in Terraform/OpenTofu syntax. We're using the spacelift Terraform provider in the configuration. We need to manage Spacelift resources (stack, context, policies) using Infrastructure as Code

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

Of all choices, make sure to set **Autodeploy** and **Enable secrets masking** to Yes. Leave all others at their default setting.

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

To check if Spacelift has detected your configuration files:

5.1. Go to your stack dashboard in Spacelift (template-default-repository-demo)
5.2. Look for the "Code" tab or section in your stack's navigation menu
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