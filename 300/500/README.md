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

- If not already existing, create a branch in your GitHub repository called "gh-pages".
- In the **Settings** of the GitHub Repository choose **Pages**.
- Under **Branch**, select "gh-pages" and "root". Click **Save**.
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
      
      # Clean up existing workspace
      - run: |
          echo "Cleaning up workspace..."
          rm -rf hatch-project
          rm -rf apps
          rm -f nx.json
          rm -f package.json
          rm -f package-lock.json
      
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
      
      # Configure base URL for GitHub Pages
      - run: |
          echo "Configuring base URL..."
          REPO_NAME=$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f2)
          echo "Base URL will be: /$REPO_NAME/"
          
          # Update vite.config.ts
          cat > apps/hatch_project/vite.config.ts << EOF
          /// <reference types='vitest' />
          import { defineConfig } from 'vite';
          import react from '@vitejs/plugin-react';
          import { nxViteTsPaths } from '@nx/vite/plugins/nx-tsconfig-paths.plugin';

          export default defineConfig({
            root: __dirname,
            base: '/$REPO_NAME/',
            cacheDir: '../../node_modules/.vite/hatch_project',

            plugins: [react(), nxViteTsPaths()],

            build: {
              outDir: '../../dist/apps/hatch_project',
              emptyOutDir: true,
              reportCompressedSize: true,
              commonjsOptions: { transformMixedEsModules: true },
            },

            test: {
              globals: true,
              cache: {
                dir: '../../node_modules/.vitest',
              },
              environment: 'jsdom',
              include: ['src/**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}'],
            },
          });
          EOF
      
      # Build for production
      - run: |
          echo "Running build command..."
          npx nx build hatch_project --configuration=production --verbose
      
      # Debug: Show build output
      - run: |
          echo "Build output structure:"
          ls -R dist/ || true
          
          echo "Looking for build files:"
          find . -type f \( \
            -name "*.js" -o \
            -name "*.html" -o \
            -name "*.css" -o \
            -name "*.json" -o \
            -name "*.ico" -o \
            -name "*.png" -o \
            -name "*.svg" \
          \) -not -path "./node_modules/*" -not -path "./.git/*" -not -path "./dist/*"
          
          echo "Contents of apps/hatch_project:"
          ls -la apps/hatch_project/
          
          echo "Contents of dist directory (if exists):"
          ls -la dist/ || true
      
      # Verify build output
      - run: |
          echo "Verifying build output..."
          if [ ! -f "dist/apps/hatch_project/index.html" ]; then
            echo "Error: index.html not found in build output!"
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

Your React application should now be deployed and accessible at your GitHub Pages URL.

You can access your GitHub Pages site at: https://vanheemstrasystems.github.io/template-default-repository-demo/

To find this URL manually:

1. Go to your repository settings (https://github.com/vanHeemstraSystems/template-default-repository-demo/settings)

2. Click on "Pages" in the left sidebar

3. Under "GitHub Pages", you should see your site's URL

**Note**: It might take a few minutes for the changes to propagate after a deployment. If you see a 404 error, wait a few minutes and try again.