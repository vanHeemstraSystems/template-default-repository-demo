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
      - run: |
          npm cache clean --force
          rm -rf node_modules
          rm -f package-lock.json
          rm -f nx.json
          rm -f project.json
      
      # Create new Nx workspace
      - run: |
          echo "Creating new Nx workspace..."
          npx create-nx-workspace@latest . \
            --preset=react \
            --appName=hatch_project \
            --style=css \
            --nxCloud=skip \
            --packageManager=npm \
            --no-interactive
      
      # Install additional dependencies
      - run: |
          echo "Installing additional dependencies..."
          npm install --save react@18.2.0 react-dom@18.2.0
          npm install --save-dev \
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
      
      # Debug: Show project structure
      - run: |
          echo "Project structure:"
          ls -la
          echo "nx.json contents:"
          cat nx.json
          echo "Available projects:"
          npx nx list
      
      # Build for production
      - run: |
          echo "Running build command..."
          npx nx build hatch_project --configuration=production --verbose
      
      # Debug: Show build output
      - run: |
          echo "Build output structure:"
          ls -R dist/ || true
          echo "All files in workspace:"
          find . -type f -not -path "./node_modules/*" -not -path "./.git/*"
      
      # Create deployment directory
      - run: |
          mkdir -p dist/apps/hatch_project
          
          if [ -d "dist/hatch_project" ]; then
            echo "Copying from dist/hatch_project"
            cp -r dist/hatch_project/* dist/apps/hatch_project/
          elif [ -d "dist/apps/hatch_project" ]; then
            echo "Build files already in correct location"
          else
            echo "Error: Could not find build output"
            exit 1
          fi
      
      # Verify deployment directory
      - run: |
          echo "Deployment directory contents:"
          ls -la dist/apps/hatch_project/
          
          if [ -z "$(ls -A dist/apps/hatch_project/)" ]; then
            echo "Error: Deployment directory is empty"
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