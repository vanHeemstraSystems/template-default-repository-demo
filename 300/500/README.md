## 500 - Deploy with Nx Cloud

To set up deployments with Nx Cloud:

1. **Connect to Nx Cloud** (if not already done):

```bash
$ cd / # Go to the root of the repository
$ npx nx connect-to-nx-cloud
```

2. **Enable Distributed Task Execution**:
- Visit https://nx.app
- Select your workspace
- Go to "Distributed Task Execution"
- Enable the feature

3. **Set up Distributed Caching**:

```bash
$ cd / # Go to the root of the repository
$ nx run-many -t build --parallel -- --mode=production
```

You will be prompted like below:

```
   ✔  nx run hatch_project:build (13s)

—————————————————————————————————————————————————————————————————

 NX   Successfully ran target build for project hatch_project (13s)

      With additional flags:
        --mode=production

View logs and investigate cache misses at https://nx.app/runs/nrF7JPvJXE
```

4. **Configure Deployment Pipeline**:
- Create a new file: `.github/workflows/deploy.yml`
- This will handle:
  - Building the application
  - Running tests
  - Deploying to your chosen platform

```
name: Deploy
on:
  push:
    branches:
      - main
  workflow_dispatch: # Allows manual triggering

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v3
        with:
          node-version: 20
      
      # Create temporary directory for the new workspace
      - run: |
          echo "Creating temporary directory..."
          mkdir -p /tmp/nx-workspace
          cd /tmp/nx-workspace
          
          echo "Creating new Nx workspace..."
          npx create-nx-workspace@latest . \
            --preset=react-monorepo \
            --appName=hatch_project \
            --style=css \
            --nxCloud=skip \
            --packageManager=npm \
            --no-interactive \
            --defaultBase=main
          
          echo "Workspace contents:"
          ls -la
          
          echo "Copying workspace files back..."
          cd $GITHUB_WORKSPACE
          cp -r /tmp/nx-workspace/* .
          cp -r /tmp/nx-workspace/.* . 2>/dev/null || true
      
      # Debug: Show project structure
      - run: |
          echo "Project structure before build:"
          ls -la
          echo "Apps directory contents:"
          ls -la apps/
          echo "nx.json contents:"
          cat nx.json || true
      
      # Build for production with verbose output
      - run: |
          echo "Running build command..."
          set -x  # Enable command echo
          npx nx build hatch_project --configuration=production --verbose
          set +x  # Disable command echo
          
          ls -R
          
          echo "Looking for build files:"
          find . -type f \( -name "*.js" -o -name "*.html" -o -name "*.css" \) -not -path "./node_modules/*"
      
      # Create and populate the output directory
      - run: |
          # Create output directory
          mkdir -p dist/apps/hatch_project
          
          # Find all build files
          echo "Searching for build files..."
          BUILD_FILES=$(find . -type f \( \
            -name "*.js" -o \
            -name "*.html" -o \
            -name "*.css" -o \
            -name "*.json" -o \
            -name "*.ico" -o \
            -name "*.png" -o \
            -name "*.svg" \
          \) -not -path "./node_modules/*" -not -path "./.git/*" -not -path "./dist/apps/hatch_project/*")
          
          if [ -n "$BUILD_FILES" ]; then
            echo "Found build files:"
            echo "$BUILD_FILES"
            
            # Copy each file to the deployment directory
            while IFS= read -r file; do
              if [ -f "$file" ]; then
                echo "Copying $file to dist/apps/hatch_project/"
                cp "$file" dist/apps/hatch_project/
              fi
            done <<< "$BUILD_FILES"
          else
            echo "No build files found!"
            echo "Contents of current directory:"
            ls -la
            echo "Contents of dist directory (if exists):"
            ls -la dist/ || true
            exit 1
          fi
      
      # Verify the output directory has files
      - run: |
          echo "Final contents of dist/apps/hatch_project:"
          ls -la dist/apps/hatch_project/
          
          if [ -z "$(ls -A dist/apps/hatch_project/)" ]; then
            echo "Error: No files found in deployment directory!"
            exit 1
          fi
      
      # Deploy to GitHub Pages
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./dist/apps/hatch_project
          enable_jekyll: false
          keep_files: false
          force_orphan: true
```
.github/workflows/deploy.yml