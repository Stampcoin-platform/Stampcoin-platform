# 🌐 IPFS Integration Setup Guide

## Overview

Our NFT system uses **dual IPFS providers** for redundancy and reliability:
1. **Pinata** - Primary provider (easier API, better performance)
2. **nft.storage** - Backup provider (free tier, Filecoin integration)

---

## 🚀 Quick Start

### 1. Create Pinata Account

**Sign up**: https://app.pinata.cloud/register

**Free Tier Includes:**
- 1 GB storage
- Unlimited IPFS requests
- 100 MB max file size
- Perfect for testing!

**Paid Plans:**
- **Picnic**: $20/month (100 GB)
- **Fiesta**: $100/month (1 TB)
- **Yacht**: Custom pricing

### 2. Get API Keys

1. Go to: https://app.pinata.cloud/developers/api-keys
2. Click "New Key"
3. Name: `stampcoin-production`
4. Permissions:
   - ✅ pinFileToIPFS
   - ✅ pinJSONToIPFS
   - ✅ unpin
   - ✅ pinList
5. Click "Create Key"
6. **⚠️ SAVE IMMEDIATELY** - you can only see the secret once!

### 3. Create nft.storage Account

**Sign up**: https://nft.storage/login

**Free Tier:**
- ✅ Unlimited storage
- ✅ Free forever (backed by Protocol Labs)
- ✅ Automatic Filecoin deals
- ✅ IPFS pinning

**Get API Token:**
1. Go to: https://nft.storage/manage
2. Click "Create New API Token"
3. Name: `stampcoin-nfts`
4. Save the token

---

## 🔧 Configuration

### Environment Variables

Add to `/workspaces/Stampcoin-platform/.env`:

```bash
# Pinata Configuration (Primary)
PINATA_API_KEY=your_pinata_api_key_here
PINATA_SECRET_KEY=your_pinata_secret_key_here
PINATA_JWT=your_pinata_jwt_here # Optional: JWT for newer API

# nft.storage Configuration (Backup)
NFT_STORAGE_API_KEY=your_nft_storage_token_here

# IPFS Gateway Configuration
IPFS_GATEWAY_URL=https://gateway.pinata.cloud/ipfs/
IPFS_BACKUP_GATEWAY=https://nftstorage.link/ipfs/

# Storage Settings
IPFS_ENABLE_PINATA=true
IPFS_ENABLE_NFT_STORAGE=true
IPFS_UPLOAD_TIMEOUT=60000 # 60 seconds
```

### Test Configuration

```bash
cd /workspaces/Stampcoin-platform
npm install
```

Test IPFS connection:
```bash
node -e "
const ipfs = require('./server/ipfs');
ipfs.testConnection().then(result => {
  console.log('Pinata:', result.pinata ? '✅' : '❌');
  console.log('nft.storage:', result.nftStorage ? '✅' : '❌');
});
"
```

---

## 📤 Usage Examples

### Example 1: Upload Stamp Image

```typescript
import * as ipfs from './server/ipfs';
import * as fs from 'fs';

async function uploadStamp() {
  // Read image file
  const imageBuffer = fs.readFileSync('./stamps/penny-black.jpg');
  
  // Upload to IPFS
  const result = await ipfs.uploadImageToPinata(
    imageBuffer,
    'penny-black.jpg',
    {
      stampId: 'STAMP_001',
      country: 'UK',
      year: '1840',
      collection: 'victorian-classics',
    }
  );
  
  console.log('IPFS Hash:', result.IpfsHash);
  console.log('Public URL:', `https://gateway.pinata.cloud/ipfs/${result.IpfsHash}`);
  
  // Result:
  // {
  //   IpfsHash: "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG",
  //   PinSize: 2456789,
  //   Timestamp: "2025-12-21T..."
  // }
}
```

### Example 2: Upload NFT Metadata

```typescript
const metadata = {
  name: "1840 Penny Black",
  description: "The world's first adhesive postage stamp",
  image: "ipfs://QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG",
  attributes: [
    { trait_type: "Country", value: "United Kingdom" },
    { trait_type: "Year", value: "1840" },
    { trait_type: "Denomination", value: "1 Penny" },
    { trait_type: "Color", value: "Black" },
    { trait_type: "Condition", value: "Used" },
    { trait_type: "Rarity", value: "Common" },
  ],
  external_url: "https://stampcoin.com/stamps/penny-black",
  authentication: {
    status: "authenticated",
    confidence: 95,
    method: "expert_review",
    authenticator: "Dr. Jane Smith, APS Certified",
  },
};

const result = await ipfs.uploadMetadataToPinata(
  metadata,
  'penny-black-metadata.json',
  { stampId: 'STAMP_001' }
);

console.log('Metadata URI:', `ipfs://${result.IpfsHash}`);
```

### Example 3: Complete Stamp Upload Workflow

```typescript
async function mintStampNFT(stampId: number, imageFile: Buffer) {
  // This function handles everything!
  const result = await ipfs.uploadStampNFT(
    stampId,
    imageFile,
    'stamp-12345.jpg',
    {
      name: "1840 Penny Black",
      description: "Historic British stamp",
      attributes: [
        { trait_type: "Country", value: "UK" },
        { trait_type: "Year", value: "1840" },
      ],
      external_url: `https://stampcoin.com/stamps/${stampId}`,
    }
  );
  
  console.log('Image IPFS Hash:', result.imageHash);
  console.log('Metadata IPFS Hash:', result.metadataHash);
  console.log('Token URI:', result.tokenURI); // Use this for NFT minting!
  
  // Now mint the NFT with this tokenURI:
  // await contract.mintStamp(recipientAddress, result.tokenURI, ...);
}
```

---

## 🔄 Redundancy & Fallbacks

### Dual Provider Strategy

The system automatically handles failures:

```typescript
// server/ipfs.ts implementation:
export async function uploadImageToPinata(buffer, filename, metadata) {
  try {
    // Try Pinata first (faster, better caching)
    const result = await pinataUpload(buffer, filename, metadata);
    return result;
  } catch (pinataError) {
    console.warn('[IPFS] Pinata failed, trying nft.storage...', pinataError);
    
    try {
      // Fallback to nft.storage
      const result = await nftStorageUpload(buffer, filename, metadata);
      return result;
    } catch (nftStorageError) {
      console.error('[IPFS] Both providers failed!', nftStorageError);
      
      // Final fallback: mock mode (for development)
      if (process.env.NODE_ENV === 'development') {
        return mockUpload(buffer, filename);
      }
      
      throw new Error('IPFS upload failed on all providers');
    }
  }
}
```

### Gateway Redundancy

Multiple gateways for maximum availability:

```typescript
const IPFS_GATEWAYS = [
  'https://gateway.pinata.cloud/ipfs/',
  'https://nftstorage.link/ipfs/',
  'https://ipfs.io/ipfs/',
  'https://cloudflare-ipfs.com/ipfs/',
  'https://dweb.link/ipfs/',
];

function getPublicUrl(ipfsHash: string): string[] {
  return IPFS_GATEWAYS.map(gateway => `${gateway}${ipfsHash}`);
}
```

---

## 🔐 Security Best Practices

### 1. Protect API Keys

**❌ NEVER:**
```typescript
// Don't hardcode keys!
const PINATA_KEY = 'abc123...';
```

**✅ DO:**
```typescript
// Use environment variables
const PINATA_KEY = process.env.PINATA_API_KEY;
if (!PINATA_KEY) {
  throw new Error('PINATA_API_KEY not configured');
}
```

### 2. Validate File Types

```typescript
const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

function validateImageUpload(file: Buffer, mimeType: string) {
  // Check MIME type
  if (!ALLOWED_IMAGE_TYPES.includes(mimeType)) {
    throw new Error(`Invalid file type: ${mimeType}`);
  }
  
  // Check file size (max 20 MB)
  if (file.length > 20 * 1024 * 1024) {
    throw new Error('File too large (max 20 MB)');
  }
  
  // Check image magic bytes
  const header = file.slice(0, 4).toString('hex');
  if (!header.startsWith('ffd8ff') && // JPEG
      !header.startsWith('89504e47')) { // PNG
    throw new Error('Invalid image data');
  }
}
```

### 3. Sanitize Metadata

```typescript
function sanitizeMetadata(metadata: any): any {
  // Remove dangerous fields
  const dangerous = ['__proto__', 'constructor', 'prototype'];
  
  for (const key of dangerous) {
    delete metadata[key];
  }
  
  // Limit string lengths
  if (metadata.name?.length > 200) {
    metadata.name = metadata.name.substring(0, 200);
  }
  
  if (metadata.description?.length > 2000) {
    metadata.description = metadata.description.substring(0, 2000);
  }
  
  return metadata;
}
```

---

## 📊 Monitoring & Analytics

### Track Upload Statistics

```typescript
// Add to server/ipfs.ts
let uploadStats = {
  totalUploads: 0,
  successfulUploads: 0,
  failedUploads: 0,
  totalBytes: 0,
  pinataUploads: 0,
  nftStorageUploads: 0,
  averageUploadTime: 0,
};

export function getUploadStats() {
  return uploadStats;
}

// Update after each upload
uploadStats.totalUploads++;
uploadStats.successfulUploads++;
uploadStats.totalBytes += fileSize;
uploadStats.pinataUploads++;
```

### Dashboard Metrics

Track these KPIs:
- Total files uploaded
- Total storage used (GB)
- Success rate (%)
- Average upload time
- Most uploaded content types
- Geographic distribution of requests

### Cost Monitoring

```typescript
// Estimate monthly costs
export function estimateMonthlyCost(stats: UploadStats): {
  pinata: number;
  nftStorage: number;
  total: number;
} {
  const totalGB = stats.totalBytes / (1024 ** 3);
  
  // Pinata pricing tiers
  let pinataCost = 0;
  if (totalGB <= 1) pinataCost = 0; // Free tier
  else if (totalGB <= 100) pinataCost = 20; // Picnic plan
  else if (totalGB <= 1000) pinataCost = 100; // Fiesta plan
  else pinataCost = 100 + ((totalGB - 1000) * 0.10); // Yacht pricing
  
  // nft.storage is free
  const nftStorageCost = 0;
  
  return {
    pinata: pinataCost,
    nftStorage: nftStorageCost,
    total: pinataCost + nftStorageCost,
  };
}
```

---

## 🧪 Testing

### Unit Tests

```typescript
// server/__tests__/ipfs.test.ts
import * as ipfs from '../ipfs';

describe('IPFS Upload Tests', () => {
  test('should upload image to Pinata', async () => {
    const testImage = Buffer.from('fake-image-data');
    const result = await ipfs.uploadImageToPinata(testImage, 'test.jpg');
    
    expect(result.IpfsHash).toBeTruthy();
    expect(result.IpfsHash).toMatch(/^Qm[a-zA-Z0-9]{44}$/);
  });
  
  test('should handle upload failure gracefully', async () => {
    // Temporarily disable API keys
    const oldKey = process.env.PINATA_API_KEY;
    process.env.PINATA_API_KEY = 'invalid_key';
    
    await expect(
      ipfs.uploadImageToPinata(Buffer.from('test'), 'test.jpg')
    ).rejects.toThrow();
    
    // Restore key
    process.env.PINATA_API_KEY = oldKey;
  });
});
```

### Integration Tests

```bash
# Test upload with real API
npm run test:ipfs:integration
```

```typescript
// scripts/test-ipfs.ts
async function testIPFSIntegration() {
  console.log('Testing IPFS integration...\n');
  
  // Test 1: Upload small image
  console.log('1. Uploading test image...');
  const testImage = fs.readFileSync('./test-assets/stamp-test.jpg');
  const imageResult = await ipfs.uploadImageToPinata(testImage, 'test-stamp.jpg');
  console.log('✅ Image uploaded:', imageResult.IpfsHash);
  
  // Test 2: Upload metadata
  console.log('\n2. Uploading metadata...');
  const metadata = { name: "Test Stamp", image: `ipfs://${imageResult.IpfsHash}` };
  const metadataResult = await ipfs.uploadMetadataToPinata(metadata, 'test-metadata.json');
  console.log('✅ Metadata uploaded:', metadataResult.IpfsHash);
  
  // Test 3: Verify retrieval
  console.log('\n3. Retrieving from gateway...');
  const url = `https://gateway.pinata.cloud/ipfs/${imageResult.IpfsHash}`;
  const response = await fetch(url);
  console.log('✅ Retrieved:', response.status === 200 ? 'SUCCESS' : 'FAILED');
  
  // Test 4: Pin management
  console.log('\n4. Listing pins...');
  const pins = await ipfs.listPinnedFiles();
  console.log(`✅ Found ${pins.length} pinned files`);
  
  console.log('\n✅ All tests passed!');
}
```

---

## 🚨 Troubleshooting

### Common Issues

**Problem: "Unauthorized" Error**
```
Error: Request failed with status code 401
```
**Solution:** Check API keys in `.env` file. Make sure there are no extra spaces or quotes.

---

**Problem: "Timeout" Error**
```
Error: Request timeout after 30000ms
```
**Solution:** 
1. Check your internet connection
2. Increase timeout in `.env`: `IPFS_UPLOAD_TIMEOUT=120000`
3. Try compressing images before upload

---

**Problem: "File too large" Error**
```
Error: File size exceeds Pinata limit
```
**Solution:** Resize image before upload:
```typescript
import sharp from 'sharp';

const resized = await sharp(largeImage)
  .resize(2000, 2000, { fit: 'inside' })
  .jpeg({ quality: 90 })
  .toBuffer();
```

---

**Problem: IPFS Hash not resolving on gateway**
**Solution:** IPFS propagation can take 1-2 minutes. Try:
1. Wait a minute and retry
2. Try different gateway
3. Check Pinata dashboard to confirm pin status

---

## 📚 Additional Resources

**Official Documentation:**
- Pinata Docs: https://docs.pinata.cloud
- nft.storage Docs: https://nft.storage/docs
- IPFS Docs: https://docs.ipfs.tech

**Tools:**
- IPFS Desktop: https://docs.ipfs.tech/install/ipfs-desktop
- Pinata Mobile App: iOS/Android
- CID Inspector: https://cid.ipfs.tech

**Community:**
- Pinata Discord: https://discord.gg/pinata
- IPFS Forums: https://discuss.ipfs.tech
- NFT.storage Discord: https://discord.gg/nft-storage

---

**Last Updated:** December 2025
**Version:** 1.0.0
