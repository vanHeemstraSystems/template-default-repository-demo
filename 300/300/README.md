# 300 - Creating a New React Monorepo

Create a new React monorepo with the following command:

```
$ cd src # navigate to the 'src' sub-directory, previously created by hatch
$ npx create-nx-workspace@latest react-monorepo --preset=react-monorepo
```

When prompted, provide the following answers:

```
NX   Let's create a new workspace [https://nx.dev/getting-started/intro]


```

This will generate the following file and directory structure underneath the ```src``` directory:

```
└─ react-monorepo
   ├─ ...
   ├─ apps
   │  ├─ react-store
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
   │  └─ react-store-e2e
   │     └─ ...
   ├─ nx.json
   ├─ tsconfig.base.json
   └─ package.json
```

MORE ...
