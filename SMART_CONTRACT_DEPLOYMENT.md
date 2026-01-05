# Smart Contract Deployment Guide

## 🔧 Prerequisites

### 1. Install Dependencies

```bash
cd contracts
npm install
```

### 2. Environment Setup

Create `contracts/.env` file:

```bash
# Network RPC URLs
POLYGON_RPC_URL=https://polygon-rpc.com
MUMBAI_RPC_URL=https://rpc-mumbai.maticvigil.com
ETHEREUM_RPC_URL=https://mainnet.infura.io/v3/YOUR_INFURA_KEY
GOERLI_RPC_URL=https://goerli.infura.io/v3/YOUR_INFURA_KEY

# Private Keys (NEVER commit these!)
DEPLOYER_PRIVATE_KEY=your_private_key_here

# Etherscan/Polygonscan API Keys (for verification)
ETHERSCAN_API_KEY=your_etherscan_key
POLYGONSCAN_API_KEY=your_polygonscan_key

# IPFS Configuration
PINATA_API_KEY=your_pinata_api_key
PINATA_SECRET_KEY=your_pinata_secret_key
NFT_STORAGE_API_KEY=your_nft_storage_key

# Contract Configuration
MINTER_ADDRESS=0x... # Address that will receive MINTER_ROLE
AUTHENTICATOR_ADDRESS=0x... # Address that will receive AUTHENTICATOR_ROLE
```

---

## 🚀 Deployment Steps

### Step 1: Compile Contracts

```bash
cd contracts
npx hardhat compile
```

Expected output:
```
Compiled 10 Solidity files successfully
```

### Step 2: Run Tests

```bash
npx hardhat test
```

All tests should pass before deployment.

### Step 3: Deploy to Testnet (Mumbai)

```bash
npx hardhat run scripts/deploy.ts --network mumbai
```

**Expected Output:**
```
Deploying StampCoinNFT...
StampCoinNFT deployed to: 0x1234...
Granting roles...
✓ MINTER_ROLE granted to 0x5678...
✓ AUTHENTICATOR_ROLE granted to 0x9abc...
Deployment complete!
```

**Save the contract address!**

### Step 4: Verify on PolygonScan

```bash
npx hardhat verify --network mumbai <CONTRACT_ADDRESS> "StampCoin NFT" "STAMP"
```

### Step 5: Test Contract Functions

```bash
npx hardhat console --network mumbai
```

Then in the console:
```javascript
const StampCoinNFT = await ethers.getContractFactory("StampCoinNFT");
const contract = await StampCoinNFT.attach("YOUR_CONTRACT_ADDRESS");

// Mint a test NFT
await contract.mintStamp(
  "0xRecipientAddress",
  "ipfs://QmExample...",
  "PHYSICAL_STAMP_001",
  true, // authenticated
  95 // confidence score
);

// Check balance
const balance = await contract.balanceOf("0xRecipientAddress");
console.log("NFT Balance:", balance.toString());
```

---

## 🌐 Network Deployment

### Mumbai Testnet (Polygon Testnet)
- **RPC**: https://rpc-mumbai.maticvigil.com
- **Chain ID**: 80001
- **Explorer**: https://mumbai.polygonscan.com
- **Faucet**: https://faucet.polygon.technology

**Advantages:**
- Free testnet MATIC
- Fast transactions (~2 seconds)
- Ethereum-compatible
- Good for testing

### Polygon Mainnet
- **RPC**: https://polygon-rpc.com
- **Chain ID**: 137
- **Explorer**: https://polygonscan.com
- **Gas Token**: MATIC

**Cost Estimate:**
- Contract deployment: ~0.1 MATIC (~$0.08)
- NFT minting: ~0.001 MATIC (~$0.0008) per mint
- Batch minting (100 NFTs): ~0.05 MATIC (~$0.04)

**Deployment Command:**
```bash
npx hardhat run scripts/deploy.ts --network polygon
```

### Ethereum Mainnet
- **RPC**: https://mainnet.infura.io/v3/YOUR_KEY
- **Chain ID**: 1
- **Explorer**: https://etherscan.io
- **Gas Token**: ETH

**Cost Estimate (at 30 gwei):**
- Contract deployment: ~0.05 ETH (~$120)
- NFT minting: ~0.002 ETH (~$5) per mint
- Batch minting: More efficient but still expensive

**⚠️ ONLY for high-value stamps due to gas costs**

---

## 🔐 Security Best Practices

### 1. Private Key Management

**❌ NEVER:**
- Commit private keys to Git
- Share private keys via email/Slack
- Use the same key for testnet and mainnet

**✅ DO:**
- Use hardware wallets (Ledger/Trezor) for mainnet
- Store keys in encrypted vaults (1Password, AWS Secrets Manager)
- Use different keys for different environments

### 2. Multi-Signature for Admin Functions

For production, use a multi-sig wallet (Gnosis Safe):
```bash
# Deploy Gnosis Safe with 3/5 signatures required
# Transfer DEFAULT_ADMIN_ROLE to Safe address
await contract.grantRole(DEFAULT_ADMIN_ROLE, gnosisSafeAddress);
await contract.renounceRole(DEFAULT_ADMIN_ROLE, deployerAddress);
```

### 3. Role Management

```javascript
// Grant minting role to backend server
await contract.grantRole(MINTER_ROLE, backendServerAddress);

// Grant authentication role to expert contract
await contract.grantRole(AUTHENTICATOR_ROLE, expertSystemAddress);

// Revoke role if compromised
await contract.revokeRole(MINTER_ROLE, compromisedAddress);
```

### 4. Emergency Pause

The contract includes a pause mechanism:
```javascript
// Pause all transfers in emergency
await contract.pause();

// Resume operations
await contract.unpause();
```

---

## 📊 Gas Optimization

### Batch Minting

Instead of:
```javascript
// ❌ Expensive: 10 separate transactions
for (let i = 0; i < 10; i++) {
  await contract.mintStamp(...);
}
```

Do:
```javascript
// ✅ Efficient: 1 transaction
await contract.batchMintStamps([
  { to: addr1, tokenURI: uri1, physicalStampId: "STAMP_001", ... },
  { to: addr2, tokenURI: uri2, physicalStampId: "STAMP_002", ... },
  // ... 10 stamps
]);
```

**Savings:** ~70% gas reduction for batch operations

### EIP-2309 (Consecutive Token Transfers)

For minting 1000+ NFTs to a single address:
```javascript
// Emits only 1 event instead of 1000
await contract.mintConsecutive(recipientAddress, 1000);
```

---

## 🔍 Monitoring & Maintenance

### 1. Set Up Event Listeners

```javascript
// Monitor all stamp mints
contract.on("StampMinted", (tokenId, to, physicalStampId, event) => {
  console.log(`New stamp minted: #${tokenId} to ${to}`);
  // Update database
  // Send notification
});

// Monitor authentications
contract.on("StampAuthenticated", (tokenId, authenticator, status, event) => {
  console.log(`Stamp #${tokenId} authenticated: ${status}`);
  // Update authentication status
});
```

### 2. Error Handling

```javascript
try {
  const tx = await contract.mintStamp(...);
  await tx.wait(); // Wait for confirmation
} catch (error) {
  if (error.code === 'INSUFFICIENT_FUNDS') {
    // Not enough MATIC/ETH for gas
  } else if (error.message.includes('Not authorized')) {
    // Address doesn't have MINTER_ROLE
  }
}
```

### 3. Dashboard Metrics

Track these metrics:
- Total NFTs minted
- Daily/weekly minting rate
- Average gas cost per mint
- Authentication rate
- Transfers per day
- Unique holders

---

## 🔗 Integration with Backend

### Update Environment Variables

Add to `/workspaces/Stampcoin-platform/.env`:

```bash
# Smart Contract Configuration
CONTRACT_ADDRESS=0x... # Deployed contract address
CONTRACT_NETWORK=polygon # or mumbai, ethereum
BLOCKCHAIN_RPC_URL=https://polygon-rpc.com
DEPLOYER_PRIVATE_KEY=0x... # For minting from backend

# Gas Configuration
MAX_GAS_PRICE=100 # gwei
GAS_LIMIT=500000
```

### Update server/nft-minting.ts

```typescript
import { ethers } from 'ethers';

const provider = new ethers.JsonRpcProvider(process.env.BLOCKCHAIN_RPC_URL);
const wallet = new ethers.Wallet(process.env.DEPLOYER_PRIVATE_KEY!, provider);

// Load contract ABI
const contractABI = require('../contracts/artifacts/contracts/StampCoinNFT.sol/StampCoinNFT.json');
const contract = new ethers.Contract(
  process.env.CONTRACT_ADDRESS!,
  contractABI.abi,
  wallet
);

export async function mintNftOnChain(
  recipientAddress: string,
  tokenURI: string,
  physicalStampId: string,
  authenticated: boolean,
  confidenceScore: number
) {
  const tx = await contract.mintStamp(
    recipientAddress,
    tokenURI,
    physicalStampId,
    authenticated,
    confidenceScore
  );
  
  const receipt = await tx.wait();
  const tokenId = receipt.logs[0].args.tokenId;
  
  return {
    tokenId: tokenId.toString(),
    transactionHash: receipt.hash,
    blockNumber: receipt.blockNumber,
  };
}
```

---

## 🧪 Testing Checklist

Before mainnet deployment, verify:

- [ ] All Hardhat tests pass
- [ ] Gas costs are acceptable
- [ ] Role management works correctly
- [ ] Batch minting saves gas
- [ ] Authentication updates work
- [ ] Provenance tracking works
- [ ] Royalties (ERC-2981) work on marketplaces
- [ ] Token URIs resolve correctly
- [ ] Pause/unpause functionality works
- [ ] Event emissions are correct

---

## 📞 Support

**Contract Issues:**
- GitHub: github.com/stampcoin/contracts/issues
- Email: contracts@stampcoin.com

**Security Concerns:**
- security@stampcoin.com
- Bug bounty program coming soon

---

## 📚 Additional Resources

- **OpenZeppelin Docs**: https://docs.openzeppelin.com/contracts
- **Hardhat Docs**: https://hardhat.org/docs
- **Polygon Docs**: https://docs.polygon.technology
- **ERC-721 Standard**: https://eips.ethereum.org/EIPS/eip-721
- **ERC-2981 Royalties**: https://eips.ethereum.org/EIPS/eip-2981

---

**Last Updated:** December 2025
**Contract Version:** 1.0.0
**Audited:** Pending (schedule audit before mainnet)
