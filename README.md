# Everest smart contracts

## 🔗 Latest deployments
| Network  | Contract addres |
| ---------| --------------------- |
| Testnet  | [0xb6Ebaec35865D3216E10e05C6838B7a1f91811FA](https://testnet.snowtrace.io/address/0xb6Ebaec35865D3216E10e05C6838B7a1f91811FA) |
| Mainnet  | Not deployed yet |

**Please update this table when you deploy a new version!**

## 📌 Get started

### 📦 Install dependencies
You need *node.js*, *npm* and *npx* installed.\
Install the project's dependencies with: `$ npm i`

### 🔧 Setup your env
Copy the sample environement file: `$ cp .env.sample .env && vi .env`

Then populate it with:
- your developer wallet private keys (`MAINNET_PRIVATE_KEY`, `FUJI_PRIVATE_KEY` and `KOVAN_PRIVATE_KEY`).
- your [coinmarketcap](https://coinmarketcap.com/api/) api key (`COINMARKETCAP_API_KEY`).
- your [snowtrace.io](https://snowtrace.io/myapikey) api key (`SNOWTRACE_API_KEY`).
- your [alpha vantage](https://www.alphavantage.co/support/#api-key) api key (`ALPHA_VANTAGE_API_KEY`).

**Your .env file should never be committed** (it is specified in the *.gitignore*)!

### ⌨️ Useful commands

- Compile: `$ npm run compile`
- Test: `$ npm run test`
- Deploy:
    - On localhost: `$ npm run <deploy-collateral-fund|deploy-price-tracker>`
    - On any other network: `$ npm run <deploy-collateral-fund|deploy-price-tracker> -- --network <network>`
- Audit:
    - Slither: `$ npm run slither`
    - Mythril: `$ npm run mythril`

Here's a simple workflow to compile, test, audit and deploy the `PriceTracker`contract on the Kovan testnet:
```sh
$ npm run compile
$ npm run test
$ npm run slither
$ npm run mythril
$ npm run deploy-price-tracker -- --network kovan
```

### 🪙 Fuji faucets

| Tokens | Link |
| ------ | ---- |
| AVAX | https://faucet.avax-test.network/ |
| LINK | https://faucets.chain.link/fuji |
