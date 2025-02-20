# 300 - Creating a New React Monorepo

Create a new React monorepo with the following command:

```
$ cd hatch-project/src # navigate to the 'hatch-project/src' sub-directory, previously created by hatch
$ npx create-nx-workspace@latest hatch_project --preset=react-monorepo
```

When prompted, provide the following answers:

```
NX   Let's create a new workspace [https://nx.dev/getting-started/intro]


```

This will generate the following file and directory structure underneath the ```/hatch-project/src``` directory:

```
└─ hatch-project
               └─ src
                    └─ hatch_project
                                   ├─ ...
                                   ├─ apps
                                   │  ├─ hatch_project
                                   │  │  ├─ public
                                   │  │  │  └─ ...
                                   │  │  ├─ src
                                   │  │  │  ├─ app
                                   │  │  │  │  ├─ app.module.css
                                   │  │  │  │  ├─ app.spec.tsx
                                   │  │  │  │  ├─ app.tsx
                                   │  │  │  │  └─ nx-welcome.tsx
                                   │  │  │  ├─ assets
                                   │  │  │  ├─ main.tsx
                                   │  │  │  └─ styles.css
                                   │  │  ├─ index.html
                                   │  │  ├─ project.json
                                   │  │  ├─ tsconfig.app.json
                                   │  │  ├─ tsconfig.json
                                   │  │  ├─ tsconfig.spec.json
                                   │  │  └─ vite.config.ts
                                   │  └─ hatch_project-e2e
                                   │     └─ ...
                                   ├─ nx.json
                                   ├─ tsconfig.base.json
                                   └─ package.json
```

**Important**: Move all files previously in ```original_hatch_project``` to ```hatch_project``` and delete ```original_hatch_project```!

### Key Points:
- **`hatch_project/nx.json`**: Configuration for the Nx workspace.
- **`hatch_project/package.json`**: Dependencies and scripts specific to the project.
- **`hatch_project/tsconfig.json`**: TypeScript configuration for the project.
- **`hatch_project/workspace.json` or `project.json`**: Defines the structure and projects within the workspace.

**IMPORTANT**: Move **nx.json** to ```hatch-project``` directory so it can connect with Nx Cloud.

```
└─ hatch-project
               ├─ ...
               ├─ nx.json
               └─ src
                    └─ hatch_project
                                   ├─ ...               
```

**IMPORTANT**: Modify **nx.json** so it can connect with Nx Cloud.

To support the nested directory structure correctly in your ```/hatch-project/nx.json```, you should adjust the paths to reflect the correct locations within the nested workspace. Here’s a revised example:

```json
{
  "$schema": "./node_modules/nx/schemas/nx-schema.json",
  "namedInputs": {
    "default": ["{projectRoot}/**/*", "sharedGlobals"],
    "production": [
      "default",
      "!{projectRoot}/.eslintrc.json",
      "!{projectRoot}/eslint.config.mjs",
      "!{projectRoot}/**/?(*.)+(spec|test).[jt]s?(x)?(.snap)",
      "!{projectRoot}/tsconfig.spec.json",
      "!{projectRoot}/jest.config.[jt]s",
      "!{projectRoot}/src/test-setup.[jt]s",
      "!{projectRoot}/test-setup.[jt]s"
    ],
    "sharedGlobals": ["{workspaceRoot}/.github/workflows/ci.yml"]
  },
  "nxCloudId": "67a3783761d0514ff26bf202",
  "plugins": [
    {
      "plugin": "@nx/webpack/plugin",
      "options": {
        "buildTargetName": "build",
        "serveTargetName": "serve",
        "previewTargetName": "preview",
        "buildDepsTargetName": "build-deps",
        "watchDepsTargetName": "watch-deps"
      }
    },
    {
      "plugin": "@nx/eslint/plugin",
      "options": {
        "targetName": "lint"
      }
    },
    {
      "plugin": "@nx/playwright/plugin",
      "options": {
        "targetName": "e2e"
      }
    },
    {
      "plugin": "@nx/jest/plugin",
      "options": {
        "targetName": "test"
      }
    }
  ],
  "targetDefaults": {
    "e2e-ci--**/*": {
      "dependsOn": ["^build"]
    }
  },
  "generators": {
    "@nx/react": {
      "application": {
        "babel": true,
        "style": "tailwind",
        "linter": "eslint",
        "bundler": "webpack"
      },
      "component": {
        "style": "tailwind"
      },
      "library": {
        "style": "tailwind",
        "linter": "eslint"
      }
    }
  },
  "projects": {
    "hatch_project": {
      "root": "src/hatch_project",
      "sourceRoot": "src/hatch_project/src",
      "projectType": "application"
    }
  }
}
```
/hatch-project/nx.json

### Key Adjustments:
- **`projects` section**: Explicitly defines the project structure, setting the `root` and `sourceRoot` to the correct paths within the nested directory.
- Ensure that all paths reflect the actual structure of your workspace.

This configuration will help Nx Cloud properly identify and manage your nested workspace.

Notice that it prepends paths with ```src/``` (e.g., ```"root": "src/hatch_project",```) to allow for our **nested** directory structure.

The path for `root` in the `projects` section should be specified relative to the workspace root, which is typically the directory where your `nx.json` file is located. 

Since your `nx.json` is at `repository-name/hatch-project/src/hatch_project/nx.json`, the paths are relative to the `src/hatch_project` directory. Thus:

- **`root`**: Should be `"src/hatch_project"` because it indicates the base directory for the project relative to the workspace's root.
- **`sourceRoot`**: Should be `"src/hatch_project/src"` for the same reason.

If you were to use the absolute path `hatch-project/src/hatch_project`, it would not be correct in the context of how Nx expects paths to be defined. Nx uses paths relative to the workspace root to maintain consistency across different environments and setups.

### Key Sections:
- **`npmScope`**: Defines the scope for your packages.
- **`affected.defaultBase`**: Specifies the default branch for determining affected projects.
- **`tasksRunnerOptions`**: Configures caching and task running options.
- **`projects`**: Contains the project configuration, specifying the root and source root paths, project type, and build targets.

Adjust paths and options as necessary to fit your specific project structure. This configuration will help Nx Cloud identify and manage your workspace correctly.

Make sure to run the **build** command from the `/hatch-project/src/hatch_project` directory - which contains the ```nx.json``` file - to ensure it recognizes the workspace correctly:
```
$ cd /hatch-project/src/hatch_project
$ nx build hatch_project
```

**Important**: 

If you don't have `workspace.json` or `project.json`, and instead have `tsconfig.base.json`, you can adjust your setup as follows:

* Option: Single Application: **Create a `workspace.json`**: If your project is a single application, you can create a `workspace.json` file in the root of the repository. Here’s a basic example:

   ```json
   {
     "version": 1,
     "projects": {
       "hatch_project": {
         "root": "hatch-project/src/hatch_project",
         "sourceRoot": "hatch-project/src/hatch_project/src",
         "projectType": "application"
       }
     }
   }
   ```

* Option: Multiple Applications: If your Nx workspace contains multiple applications, you should structure your `workspace.json` (or `project.json`) to reflect each application. Here’s how to set it up:

### Example `workspace.json`

Create a `workspace.json` file in the root of the repository with the following structure:

```json
{
  "version": 1,
  "projects": {
    "app1": {
      "root": "hatch-project/src/hatch_project/app1",
      "sourceRoot": "hatch-project/src/hatch_project/app1/src",
      "projectType": "application"
    },
    "app2": {
      "root": "hatch-project/src/hatch_project/app2",
      "sourceRoot": "hatch-project/src/hatch_project/app2/src",
      "projectType": "application"
    },
    "hatch_project": {
      "root": "hatch-project/src/hatch_project",
      "sourceRoot": "hatch-project/src/hatch_project/src",
      "projectType": "application"
    }
  }
}
```

### Key Points:
- **Project Names**: Replace `app1`, `app2`, etc., with meaningful names for your applications.
- **Root and Source Root**: Adjust the `root` and `sourceRoot` paths to match the actual structure of your applications within the `hatch_project` directory.

### Additional Considerations:
- **Dependencies**: If applications depend on shared libraries or each other, ensure to define those dependencies in the `nx.json` file.
- **Configuration Files**: Each application may also have its own `tsconfig.json` if needed, or you can use a shared `tsconfig.base.json` for common settings.

### Example Directory Structure
Your directory structure might look like this:

```
/
├── hatch-project/
│    └── src/
│        └── hatch_project/
│            ├── REMOVE: nx.json
│            ├── REMOVE: workspace.json
│            ├── REMOVE: tsconfig.base.json
│            ├── app1/
│            │   └── src/
│            │       └── main.tsx
│            ├── app2/
│            │   └── src/
│            │       └── main.tsx
├── nx.json
├── workspace.json
├── tsconfig.base.json
```

### Running Commands
After setting up `workspace.json`, you can run commands like:

```bash
nx build app1
nx build app2
```

This structure will help Nx Cloud recognize and manage multiple applications effectively.

This structure should allow Nx Cloud to detect the workspace properly.

Run the command to **connect** your workspace to Nx Cloud from the root of the repository, specifically:

```
$ cd /../../../
$ npm init -y # If no package.json exists
# Go through the initialization steps
$ npm install -g nx@latest # If not already installed
$ npm install --save-dev nx @nrwl/workspace
$ npm install --save-dev @nx/webpack
$ npm install --save-dev @nx/react @nx/eslint @nx/playwright @nx/jest
```

Now commit these changes to GitHub repository before continuing!

The command to connect to Nx Cloud is:

```
$ nx connect-to-nx-cloud
```

This will initiate the configuration process for Nx Cloud within your workspace.

You will be prompted as follows:

```
 NX   ✔ This workspace already has Nx Cloud set up

If you have not done so already, connect your workspace to your Nx Cloud account with the following URL:

https://cloud.nx.app/connect/Ehf8PFoDWR
```

Finish the CI setup by visiting: https://cloud.nx.app/connect/eXwFUcpdBt # **Note**: the URL will differ per creation. See [Enable GitHub PR Integration](https://nx.dev/ci/recipes/source-control-integration/github) and/or watch [PNPM-CI: Connect Your Workspace to Nx Cloud for Enhanced Collaboration](https://www.youtube.com/watch?v=8mqHXYIl_qI).

## Nested app directories

You can have nested folders, no problems. 👍 Here's a [live example](https://github.com/codyslexia/nexa/tree/main/apps/graphql). You can see that apps/graphql/users is a nested directory where users is the actual project. There's also this [other example](https://github.com/nrwl/nx-incremental-large-repo/tree/master/libs/app0/lib1) from the ```nrwl``` family.

## Nx ignore

You can place a ```.nxignore``` in the root of the project directory, here ```/hatch-project/src/hatch_project/.nxignore```.

For example to ignore any files in ```.next```:

```
.next
```
.nxignore


Now to run a build, run the following command from the root of the repository:

```
npx nx run-many -t build
```

To run a build for all applications, run the following command from the root of the repository:

```
npx nx run-many -t build --all
```