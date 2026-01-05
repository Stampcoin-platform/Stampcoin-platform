/**
 * IPFS Storage Service
 * Integrates with Pinata and nft.storage for decentralized file storage
 */

import axios from 'axios';
import FormData from 'form-data';
import { Readable } from 'stream';

export interface IpfsUploadResult {
  ipfsHash: string;
  ipfsUrl: string;
  pinataUrl?: string;
  gatewayUrl: string;
}

export interface NftStorageUploadResult {
  cid: string;
  url: string;
  gatewayUrl: string;
}

/**
 * Upload image to Pinata IPFS
 */
export async function uploadImageToPinata(
  fileBuffer: Buffer,
  fileName: string,
  mimeType: string
): Promise<IpfsUploadResult> {
  const apiKey = process.env.PINATA_API_KEY;
  const apiSecret = process.env.PINATA_API_SECRET;

  if (!apiKey || !apiSecret) {
    console.warn('[IPFS] Pinata credentials not configured, using mock response');
    const mockHash = `Qm${Buffer.from(fileName).toString('hex').substring(0, 44)}`;
    return {
      ipfsHash: mockHash,
      ipfsUrl: `ipfs://${mockHash}`,
      gatewayUrl: `https://gateway.pinata.cloud/ipfs/${mockHash}`,
    };
  }

  try {
    const formData = new FormData();
    formData.append('file', fileBuffer, {
      filename: fileName,
      contentType: mimeType,
    });

    const metadata = JSON.stringify({
      name: fileName,
      keyvalues: {
        type: 'stamp-image',
        uploadedAt: new Date().toISOString(),
      },
    });
    formData.append('pinataMetadata', metadata);

    const options = JSON.stringify({
      cidVersion: 1,
    });
    formData.append('pinataOptions', options);

    const response = await axios.post(
      'https://api.pinata.cloud/pinning/pinFileToIPFS',
      formData,
      {
        maxBodyLength: Infinity,
        headers: {
          'Content-Type': `multipart/form-data; boundary=${formData.getBoundary()}`,
          pinata_api_key: apiKey,
          pinata_secret_api_key: apiSecret,
        },
      }
    );

    const ipfsHash = response.data.IpfsHash;
    console.log('[IPFS] Image uploaded to Pinata:', ipfsHash);

    return {
      ipfsHash,
      ipfsUrl: `ipfs://${ipfsHash}`,
      pinataUrl: `https://gateway.pinata.cloud/ipfs/${ipfsHash}`,
      gatewayUrl: `https://gateway.pinata.cloud/ipfs/${ipfsHash}`,
    };
  } catch (error: any) {
    console.error('[IPFS] Pinata upload failed:', error.message);
    throw new Error(`Failed to upload to Pinata: ${error.message}`);
  }
}

/**
 * Upload JSON metadata to Pinata IPFS
 */
export async function uploadMetadataToPinata(
  metadata: any,
  name: string
): Promise<IpfsUploadResult> {
  const apiKey = process.env.PINATA_API_KEY;
  const apiSecret = process.env.PINATA_API_SECRET;

  if (!apiKey || !apiSecret) {
    console.warn('[IPFS] Pinata credentials not configured, using mock response');
    const mockHash = `Qm${Buffer.from(name).toString('hex').substring(0, 44)}`;
    return {
      ipfsHash: mockHash,
      ipfsUrl: `ipfs://${mockHash}`,
      gatewayUrl: `https://gateway.pinata.cloud/ipfs/${mockHash}`,
    };
  }

  try {
    const response = await axios.post(
      'https://api.pinata.cloud/pinning/pinJSONToIPFS',
      {
        pinataContent: metadata,
        pinataMetadata: {
          name,
          keyvalues: {
            type: 'nft-metadata',
            uploadedAt: new Date().toISOString(),
          },
        },
        pinataOptions: {
          cidVersion: 1,
        },
      },
      {
        headers: {
          'Content-Type': 'application/json',
          pinata_api_key: apiKey,
          pinata_secret_api_key: apiSecret,
        },
      }
    );

    const ipfsHash = response.data.IpfsHash;
    console.log('[IPFS] Metadata uploaded to Pinata:', ipfsHash);

    return {
      ipfsHash,
      ipfsUrl: `ipfs://${ipfsHash}`,
      pinataUrl: `https://gateway.pinata.cloud/ipfs/${ipfsHash}`,
      gatewayUrl: `https://gateway.pinata.cloud/ipfs/${ipfsHash}`,
    };
  } catch (error: any) {
    console.error('[IPFS] Pinata metadata upload failed:', error.message);
    throw new Error(`Failed to upload metadata to Pinata: ${error.message}`);
  }
}

/**
 * Upload to nft.storage (alternative/backup to Pinata)
 */
export async function uploadToNftStorage(
  fileBuffer: Buffer,
  fileName: string,
  mimeType: string
): Promise<NftStorageUploadResult> {
  const apiKey = process.env.NFT_STORAGE_API_KEY;

  if (!apiKey) {
    console.warn('[IPFS] NFT.Storage credentials not configured, using mock response');
    const mockCid = `bafybei${Buffer.from(fileName).toString('hex').substring(0, 52)}`;
    return {
      cid: mockCid,
      url: `ipfs://${mockCid}`,
      gatewayUrl: `https://nftstorage.link/ipfs/${mockCid}`,
    };
  }

  try {
    const formData = new FormData();
    formData.append('file', fileBuffer, {
      filename: fileName,
      contentType: mimeType,
    });

    const response = await axios.post('https://api.nft.storage/upload', formData, {
      headers: {
        Authorization: `Bearer ${apiKey}`,
        ...formData.getHeaders(),
      },
    });

    const cid = response.data.value.cid;
    console.log('[IPFS] File uploaded to NFT.Storage:', cid);

    return {
      cid,
      url: `ipfs://${cid}`,
      gatewayUrl: `https://nftstorage.link/ipfs/${cid}`,
    };
  } catch (error: any) {
    console.error('[IPFS] NFT.Storage upload failed:', error.message);
    throw new Error(`Failed to upload to NFT.Storage: ${error.message}`);
  }
}

/**
 * Pin existing IPFS hash to Pinata
 */
export async function pinToIPFS(ipfsHash: string, name: string): Promise<boolean> {
  const apiKey = process.env.PINATA_API_KEY;
  const apiSecret = process.env.PINATA_API_SECRET;

  if (!apiKey || !apiSecret) {
    console.warn('[IPFS] Pinata credentials not configured, skipping pinning');
    return false;
  }

  try {
    await axios.post(
      'https://api.pinata.cloud/pinning/pinByHash',
      {
        hashToPin: ipfsHash,
        pinataMetadata: {
          name,
          keyvalues: {
            pinnedAt: new Date().toISOString(),
          },
        },
      },
      {
        headers: {
          'Content-Type': 'application/json',
          pinata_api_key: apiKey,
          pinata_secret_api_key: apiSecret,
        },
      }
    );

    console.log('[IPFS] Hash pinned to Pinata:', ipfsHash);
    return true;
  } catch (error: any) {
    console.error('[IPFS] Pinning failed:', error.message);
    return false;
  }
}

/**
 * Unpin from Pinata (for cleanup/cost management)
 */
export async function unpinFromIPFS(ipfsHash: string): Promise<boolean> {
  const apiKey = process.env.PINATA_API_KEY;
  const apiSecret = process.env.PINATA_API_SECRET;

  if (!apiKey || !apiSecret) {
    return false;
  }

  try {
    await axios.delete(`https://api.pinata.cloud/pinning/unpin/${ipfsHash}`, {
      headers: {
        pinata_api_key: apiKey,
        pinata_secret_api_key: apiSecret,
      },
    });

    console.log('[IPFS] Hash unpinned from Pinata:', ipfsHash);
    return true;
  } catch (error: any) {
    console.error('[IPFS] Unpinning failed:', error.message);
    return false;
  }
}

/**
 * Get pinned file list from Pinata
 */
export async function getPinnedFiles(limit: number = 10): Promise<any[]> {
  const apiKey = process.env.PINATA_API_KEY;
  const apiSecret = process.env.PINATA_API_SECRET;

  if (!apiKey || !apiSecret) {
    return [];
  }

  try {
    const response = await axios.get('https://api.pinata.cloud/data/pinList', {
      params: {
        status: 'pinned',
        pageLimit: limit,
      },
      headers: {
        pinata_api_key: apiKey,
        pinata_secret_api_key: apiSecret,
      },
    });

    return response.data.rows || [];
  } catch (error: any) {
    console.error('[IPFS] Failed to get pinned files:', error.message);
    return [];
  }
}

/**
 * Helper: Convert IPFS URL to HTTP gateway URL
 */
export function ipfsToGateway(ipfsUrl: string, gateway: string = 'pinata'): string {
  if (!ipfsUrl.startsWith('ipfs://')) {
    return ipfsUrl;
  }

  const hash = ipfsUrl.replace('ipfs://', '');
  
  const gateways: Record<string, string> = {
    pinata: 'https://gateway.pinata.cloud/ipfs/',
    ipfs: 'https://ipfs.io/ipfs/',
    cloudflare: 'https://cloudflare-ipfs.com/ipfs/',
    nftstorage: 'https://nftstorage.link/ipfs/',
  };

  return `${gateways[gateway] || gateways.pinata}${hash}`;
}

/**
 * Upload stamp image and metadata together (complete NFT workflow)
 */
export async function uploadStampNFT(
  imageBuffer: Buffer,
  imageName: string,
  mimeType: string,
  metadata: any
): Promise<{
  imageIpfs: IpfsUploadResult;
  metadataIpfs: IpfsUploadResult;
}> {
  console.log('[IPFS] Starting complete NFT upload workflow...');

  // 1. Upload image
  const imageIpfs = await uploadImageToPinata(imageBuffer, imageName, mimeType);
  console.log('[IPFS] Image uploaded:', imageIpfs.ipfsUrl);

  // 2. Update metadata with image IPFS URL
  const updatedMetadata = {
    ...metadata,
    image: imageIpfs.ipfsUrl,
  };

  // 3. Upload metadata
  const metadataIpfs = await uploadMetadataToPinata(
    updatedMetadata,
    `${imageName}-metadata.json`
  );
  console.log('[IPFS] Metadata uploaded:', metadataIpfs.ipfsUrl);

  return {
    imageIpfs,
    metadataIpfs,
  };
}
