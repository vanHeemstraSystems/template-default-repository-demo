# 400 - Building the New React Monorepo

## 100 - Test the Built Application

First, let's serve the application:

```
$ cd / # Go to the root of the repository
$ npx nx serve hatch_project
```

This will:
- Start a development server
- Usually on http://localhost:4200
- Auto-reload on changes

Here is an example of what you will see as the landing page:

![Image](https://github.com/user-attachments/assets/f49661fe-48dc-4e82-8a1d-a70fae1bae15)

http://localhost:4200

**TIP**: Install the [Nx Console for Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=nrwl.angular-console&utm_source=nx-project). As we use **Cursor.io**, one can also install the same in Cursor from the Extensions Marketplace (look for ```Nx Console```).

## 200 - Set up Continuous Integration

To set up CI with GitHub Actions:

a. Create the workflow file:

```
$ cd / # Go to the root of the repository
$ mkdir -p .github/workflows
```

b. Create the CI configuration:

```
name: CI
on:
  push:
    branches:
      - main
  pull_request:

jobs:
  main:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v3
        with:
          node-version: 20
          cache: 'npm'
      - run: npm cache clean --force
      - run: npm ci
      - run: npm install -g @nrwl/cli
      - run: |
          npm install --save-dev @swc-node/register @swc/core \
          @nx/webpack webpack-cli \
          @nx/eslint-plugin eslint-plugin-playwright \
          @playwright/test jest \
          @nx/jest @nx/react @nx/eslint @nx/playwright
      - run: npx nx run-many -t build --verbose
      - run: npx nx run-many -t test
```
.github/workflows/ci.yml

Our GitHub Actions workflow is now set up and successfully running builds and tests.
