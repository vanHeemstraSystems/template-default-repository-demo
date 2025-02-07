# Nx

Based on "Installation" at https://nx.dev/getting-started/installation

Install **Nx** (required for Nx Monorepos and Nx Cloud) globally as follows:

```
$ npm add --global nx@latest
```

To use **nx** directly, you can now just use:

```
$ nx --version
```

To update **nx**, run:

```
$ cd hatch-project/src/hatch_project
$ npx nx migrate latest # if nx has not yet been installed
$ nx migrate latest     # if nx has already been installed
```