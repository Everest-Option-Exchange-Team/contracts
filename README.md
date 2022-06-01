# Everest smart contracts

## 🔗 Latest deployments
**Please update these tables when you deploy a new version!**

### Main contracts
| Contract | Network  | Contract addres |
| ---------| -------- | --------------- |
| SimpleHubV1 | Kovan | [0x5B580Ec564FAF6FE2B95C6A316EF286D707e323d](https://kovan.etherscan.io/address/0x5B580Ec564FAF6FE2B95C6A316EF286D707e323d) |
| CollateralFundV1 | Kovan | [0xdE4E6EFcaaEaa997A77b812eCE98739948391c51](https://kovan.etherscan.io/address/0xdE4E6EFcaaEaa997A77b812eCE98739948391c51) |
| PriceTrackerV1 | Kovan | [0x243AfF679C667ddFCa073498b9EF804320C84bEB](https://kovan.etherscan.io/address/0x243AfF679C667ddFCa073498b9EF804320C84bEB) |

### Synthetic Assets contracts
| Contract | Network  | Contract addres |
| ---------| -------- | --------------- |
| SyntheticAAPL | Kovan | [0x0e57567140BA8171e243c8E62edf938582135Ab3](https://kovan.etherscan.io/address/0x0e57567140BA8171e243c8E62edf938582135Ab3) |
| SyntheticTSLA | Kovan | [0xe7d15029e5Fde6E4f61C571DF98213f34fE5D08e](https://kovan.etherscan.io/address/0xe7d15029e5Fde6E4f61C571DF98213f34fE5D08e) |
| SyntheticMSFT | Kovan | [0x814216048E3b619C6d75908aF7F7a1Db14628F2c](https://kovan.etherscan.io/address/0x814216048E3b619C6d75908aF7F7a1Db14628F2c) |
| SyntheticABNB | Kovan | [0x62E7cAC55C9B8D4419F79446137b673d1E94444B](https://kovan.etherscan.io/address/0x62E7cAC55C9B8D4419F79446137b673d1E94444B) |
| SyntheticGOOG | Kovan | [0xC10Daf71FC948285a9F0FBEF301F21A4ca2de0Bb](https://kovan.etherscan.io/address/0xC10Daf71FC948285a9F0FBEF301F21A4ca2de0Bb) |

## 📌 Get started

### 📦 Install dependencies
You need *node.js*, *npm* and *npx* installed.\
Install the project's dependencies with: `$ npm i`

### 🔧 Setup your env
Copy the sample environement file: `$ cp .env.sample .env && vi .env`

Then populate it with:
- your [alchemy](https://dashboard.alchemyapi.io/) api key (`ALCHEMY_API_KEY`).
- your [alpha vantage](https://www.alphavantage.co/support/#api-key) api key (`ALPHA_VANTAGE_API_KEY`).
- your [coinmarketcap](https://coinmarketcap.com/api/) api key (`COINMARKETCAP_API_KEY`).
- your [etherscan.io](https://etherscan.io/myapikey) api key (`ETHERSCAN_API_KEY`).
- your developer wallet private keys (`MAINNET_PRIVATE_KEY`, `FUJI_PRIVATE_KEY` and `KOVAN_PRIVATE_KEY`).

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
