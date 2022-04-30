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
- your developer wallet private keys (`MAINNET_PRIVATE_KEY` and `FUJI_PRIVATE_KEY`).
- your [coinmarketcap](https://coinmarketcap.com/api/) api key (`COINMARKETCAP_API_KEY`).

**Your .env file should never be committed** (it is specified in the *.gitignore*)!

### ⌨️ Useful commands

- Compile: `$ npm run compile`
- Test: `$ npm run test`
- Deploy:
    - To local network: `$ npm run deploy-local`  
    - To fuji tesnet: `$ npm run deploy-local`  
    - To avalanche mainnnet: `$ npm run deploy-local`  
- Audit:
    - With slither: `$ slither .`
    - With mythril: `$ myth analyze contracts/Fund.sol`

### 🪙 Fuji faucets

| Tokens | Link |
| ------ | ---- |
| AVAX | https://faucet.avax-test.network/ |
| LINK | https://faucets.chain.link/fuji |
