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

## ⚙️ Compile contracts
Compile the smart contracts: `$ npx hardhat compile`

## 🧪 Test contracts
Test the smart contracts: `$ npx hardhat test`

## 🚀 Deploy contracts 
Deploy the smart contracts to a blockchain: `$ npx hardhat run scripts/deploy.js`
