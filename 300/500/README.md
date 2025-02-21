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
      
      # Clean install
      - run: npm cache clean --force
      - run: rm -rf node_modules
      - run: npm install -g nx@latest
      
      # Install all dependencies with --ignore-scripts
      - run: |
          npm install --ignore-scripts --save react@18.2.0 react-dom@18.2.0 && \
          npm install --ignore-scripts --save-dev \
          @types/react@18.2.0 @types/react-dom@18.2.0 \
          @swc-node/register @swc/core \
          @nx/webpack webpack-cli \
          @nx/eslint-plugin eslint-plugin-playwright \
          @playwright/test jest jest-environment-jsdom \
          @nx/jest @nx/react @nx/eslint @nx/playwright \
          typescript-eslint @typescript-eslint/parser @typescript-eslint/eslint-plugin \
          eslint ts-jest \
          eslint-plugin-import eslint-plugin-react eslint-plugin-react-hooks eslint-plugin-jsx-a11y \
          @testing-library/react @testing-library/jest-dom @testing-library/user-event

      # Debug: Show project configuration
      - run: |
          echo "Project configuration:"
          cat project.json || true
          cat workspace.json || true
          cat nx.json || true
      
      # Build for production with verbose output
      - run: npx nx build hatch_project --prod --verbose
      
      # Debug: Show build output structure
      - run: |
          echo "Current working directory:"
          pwd
          echo "All files in current directory:"
          ls -la
          echo "All build files:"
          find . -type f -not -path "./node_modules/*" -not -path "./.git/*"
          echo "Contents of dist directory (if exists):"
          ls -R dist/ || true
          echo "Contents of apps directory (if exists):"
          ls -R apps/ || true
      
      # Create the output directory
      - run: mkdir -p dist/apps/hatch_project
      
      # Copy build files from the correct location
      - run: |
          # First, try to find the build output directory
          BUILD_DIR=""
          
          if [ -d "dist/hatch_project" ]; then
            BUILD_DIR="dist/hatch_project"
          elif [ -d "dist/apps/hatch_project" ]; then
            BUILD_DIR="dist/apps/hatch_project"
          elif [ -d "apps/hatch_project/dist" ]; then
            BUILD_DIR="apps/hatch_project/dist"
          fi
          
          if [ -n "$BUILD_DIR" ]; then
            echo "Found build directory: $BUILD_DIR"
            cp -r "$BUILD_DIR"/* dist/apps/hatch_project/
          else
            echo "Searching for build files..."
            BUILD_FILES=$(find . -type f \( \
              -name "main.*.js" -o \
              -name "runtime.*.js" -o \
              -name "polyfills.*.js" -o \
              -name "vendor.*.js" -o \
              -name "styles.*.css" -o \
              -name "index.html" \
            \) -not -path "./node_modules/*" -not -path "./.git/*" -not -path "./dist/apps/hatch_project/*")
            
            if [ -n "$BUILD_FILES" ]; then
              echo "Found build files:"
              echo "$BUILD_FILES"
              for file in $BUILD_FILES; do
                echo "Copying $file to dist/apps/hatch_project/"
                cp "$file" dist/apps/hatch_project/
              done
            else
              echo "No build files found!"
              exit 1
            fi
          fi
      
      # Verify the output directory has files
      - run: |
          echo "Final contents of dist/apps/hatch_project:"
          ls -la dist/apps/hatch_project/
      
      # Deploy to GitHub Pages
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./dist/apps/hatch_project
          enable_jekyll: false
          keep_files: true
          force_orphan: false
```
.github/workflows/deploy.yml