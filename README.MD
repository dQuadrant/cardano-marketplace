Cardano Simple Marketplace
==========================

Webapp and cli for marketplace in cardano testnet using Kuber libarary.

#### marketplace-cli
This  component is command line tool for interacting with the marketplace. Cli used kuber library, which handles transaction creation and submission to node 

![something](./docs/cli.svg)


#### marketplace-frontend
Frontend vue project is located [here](./frontend).
- It connects to an existing kuber server to construct transactions.
- Lists tokens onSale using blockfrost APIs.

![something](./docs/frontend.svg)



### Project structure

- **marketplace-plutus/** - contains plutus contract code for simple marketplace
- **marketplace-cli/** - contains entry point for cli and cli commands and their parsing 
- **marketplace-core/** - contains marketplace core functions and  interaction with kuber library
- **frontend/** - contains client side for marketplace


### IDE Setup
 
VS code  with devcontainer enabled is the fastest way to get started with the project. To Use the cli, cardano-node should also be installed and running.

## Usage:
- [Using frontend](./frontend) : (Preferred Way) Its easier to get started.
- [Using Cli](./docs/cli.md)


## Building locally
 [Building locally](./docs/build.md)
