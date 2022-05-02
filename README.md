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
    - Fund contract: `$ npm run deploy-fund --network <network>`
    - StockAPIConsumer contract: `$ npm run deploy-api-consumer --network <network>`
    You can either deploy on kovan, fuji
    Don't specify the network if you want to deploy on localhost.
- Audit:
    - With slither: `$ npm run slither`
    - With mythril: `$ npm run mythril`

### 🪙 Fuji faucets

| Tokens | Link |
| ------ | ---- |
| AVAX | https://faucet.avax-test.network/ |
| LINK | https://faucets.chain.link/fuji |
