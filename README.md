# Everest smart contracts

## 🔗 Latest deployments
| Network  | Contract addres |
| ------------ | --------------------- |
| Testnet  | [0xb6Ebaec35865D3216E10e05C6838B7a1f91811FA](https://testnet.snowtrace.io/address/0xb6Ebaec35865D3216E10e05C6838B7a1f91811FA) |
| Mainnet  | Not deployed yet |

**Please update this table when you deploy a new version!**

## 📦 Install dependencies
You need *node.js*, *npm* and *npx* installed.\
Install the project's dependencies with: `$ npm i`

## 🔧 Setup your env
Copy the sample environement file: `$ cp .env.sample .env && vi .env`

Then populate it with:
- your developer wallet private keys (`MAINNET_PRIVATE_KEY` and `FUJI_PRIVATE_KEY`).
- your [coinmarketcap](https://coinmarketcap.com/api/) api key (`COINMARKETCAP_API_KEY`).

**Your .env file should never be committed** (it is specified in the *.gitignore*)!

# Useful commands for smart contract 

## ⚙️ Compile contracts
Compile the smart contracts: `$ npm run compile`

## 🧪 Test contracts
Test the smart contracts: `$ npm run test`

## 🚀 Deploy contracts 
Deploy the smart contracts to local network: `$ npm run deploy-local`
Deploy the smart contracts to fuji network: `$ npm run deploy-local`
Deploy the smart contracts to mainnnet: `$ npm run deploy-local`

## Mythril
`$ myth analyze contracts/Fund.sol`

## Slither.io
`$ slither .`