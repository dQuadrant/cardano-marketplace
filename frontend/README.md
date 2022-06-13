# Marketplace Frontend

Vue project for interacting with marketplace contract on cardano testnet. Frontend project runs independ of the `marketplace-cli` or `marketplace-core` and only needs a running    [kuber](https://github.com/dQuadrant/kuber) API server instance.

![](../docs/frontend.svg)

## Recommended IDE Setup

[VSCode](https://code.visualstudio.com/) + [Volar](https://marketplace.visualstudio.com/items?itemName=johnsoncodehk.volar) (and disable Vetur) + [TypeScript Vue Plugin (Volar)](https://marketplace.visualstudio.com/items?itemName=johnsoncodehk.vscode-typescript-vue-plugin).



### Project Setup

```sh
npm install
```

#### Compile and Hot-Reload for Development

```sh
npm run dev
```
        
**Configuration file : [src/config.ts](./src/config.ts)**

You can either use `https://testnet.cnftregistry.io/kuber`  for apiServer. Better approach is to run your own kuber server and cardano-node instance locally.

