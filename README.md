# Everest smart contracts

## 🔗 Latest deployments
| Network  | Contract addres |
| ------------ | --------------------- |
| Testnet  | [0x5081f431918Ccc62DBDfaCBc11f34B4166A27450](https://testnet.snowtrace.io/address/0x5081f431918Ccc62DBDfaCBc11f34B4166A27450) |
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
