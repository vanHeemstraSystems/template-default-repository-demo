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

      # Debug: Show project structure before build
      - run: pwd
      - run: ls -la
      - run: npx nx list
      
      # Build for production with verbose output
      - run: npx nx build hatch_project --prod --verbose
      
      # Debug: Show build output structure
      - run: ls -R dist || true
      - run: find . -name "*.js" -o -name "*.html" -o -name "*.css"
      - run: pwd && ls -la && ls -la dist/ && ls -la dist/apps/ || true
      
      # Create the output directory and ensure it exists
      - run: |
          mkdir -p dist/apps/hatch_project
          touch dist/apps/hatch_project/.gitkeep
      
      # Copy all build files to the correct location
      - run: |
          echo "Current directory structure:"
          find . -type f -name "*.js" -o -name "*.html" -o -name "*.css"
          
          if [ -d "dist" ]; then
            echo "Contents of dist directory:"
            ls -R dist/
            
            # Try different possible build output locations
            for dir in "dist/hatch_project" "dist/apps/hatch_project" "dist"; do
              if [ -d "$dir" ]; then
                echo "Found files in $dir:"
                ls -la "$dir"
                echo "Copying files from $dir to dist/apps/hatch_project"
                cp -r "$dir"/* dist/apps/hatch_project/ || true
              fi
            done
          else
            echo "dist directory not found"
            exit 1
          fi
      
      # Verify the output directory has files
      - run: |
          echo "Final contents of dist/apps/hatch_project:"
          ls -la dist/apps/hatch_project/
      
      # Optional: Run tests before deploying
      - run: npx nx test hatch_project
      
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