#!/bin/bash

# StampCoin Platform - Production Configuration Script
# This script helps configure optional services for full production deployment

set -e

echo "🔧 StampCoin Platform - Production Configuration"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if flyctl is installed
if ! command -v flyctl &> /dev/null; then
    echo -e "${RED}❌ flyctl CLI not found. Please install it first:${NC}"
    echo "   https://fly.io/docs/hands-on/install-flyctl/"
    exit 1
fi

# Check authentication
if ! flyctl auth whoami &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not authenticated with Fly.io. Running login...${NC}"
    flyctl auth login
fi

echo -e "${BLUE}Current Fly.io User:${NC} $(flyctl auth whoami)"
echo -e "${BLUE}App Name:${NC} stampcoin-platform"
echo ""

# Menu
show_menu() {
    echo "Select what you want to configure:"
    echo "1) IPFS Storage (Pinata + nft.storage)"
    echo "2) AI Authentication Services (Google Vision + Azure Vision)"
    echo "3) Smart Contract Deployment (Infura + Alchemy)"
    echo "4) Analytics (Umami)"
    echo "5) OAuth Configuration"
    echo "6) View Current Secrets"
    echo "7) Reset All Secrets"
    echo "8) Exit"
    echo ""
}

# IPFS Configuration
configure_ipfs() {
    echo -e "${BLUE}📦 IPFS Storage Configuration${NC}"
    echo "================================"
    echo ""
    echo "You'll need API keys from:"
    echo "  1. Pinata (https://pinata.cloud) - for stamp images"
    echo "  2. nft.storage (https://nft.storage) - for NFT metadata"
    echo ""
    
    read -p "Do you have Pinata API credentials? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter Pinata API Key: " PINATA_API_KEY
        read -p "Enter Pinata API Secret: " PINATA_API_SECRET
        read -p "Enter Pinata JWT Token: " PINATA_JWT
        
        echo "Setting Pinata secrets..."
        flyctl secrets set PINATA_API_KEY="$PINATA_API_KEY" PINATA_API_SECRET="$PINATA_API_SECRET" PINATA_JWT="$PINATA_JWT"
        echo -e "${GREEN}✅ Pinata configured${NC}"
    fi
    
    read -p "Do you have nft.storage API key? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter nft.storage API Key: " NFT_STORAGE_API_KEY
        
        echo "Setting nft.storage secret..."
        flyctl secrets set NFT_STORAGE_API_KEY="$NFT_STORAGE_API_KEY"
        echo -e "${GREEN}✅ nft.storage configured${NC}"
    fi
    
    echo ""
}

# AI Configuration
configure_ai() {
    echo -e "${BLUE}🤖 AI Authentication Services Configuration${NC}"
    echo "============================================"
    echo ""
    echo "You'll need API keys from:"
    echo "  1. Google Cloud Vision (https://console.cloud.google.com)"
    echo "  2. Azure Vision (https://portal.azure.com)"
    echo ""
    
    read -p "Do you have Google Vision API key? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter Google Vision API Key: " GOOGLE_VISION_API_KEY
        
        echo "Setting Google Vision secret..."
        flyctl secrets set GOOGLE_VISION_API_KEY="$GOOGLE_VISION_API_KEY"
        echo -e "${GREEN}✅ Google Vision configured${NC}"
    fi
    
    read -p "Do you have Azure Vision credentials? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter Azure Vision Endpoint (https://...): " AZURE_VISION_ENDPOINT
        read -p "Enter Azure Vision API Key: " AZURE_VISION_KEY
        
        echo "Setting Azure Vision secrets..."
        flyctl secrets set AZURE_VISION_ENDPOINT="$AZURE_VISION_ENDPOINT" AZURE_VISION_KEY="$AZURE_VISION_KEY"
        echo -e "${GREEN}✅ Azure Vision configured${NC}"
    fi
    
    echo ""
}

# Smart Contract Configuration
configure_contracts() {
    echo -e "${BLUE}🔗 Smart Contract Deployment Configuration${NC}"
    echo "=========================================="
    echo ""
    echo "You'll need accounts/keys from:"
    echo "  1. Infura (https://infura.io) - Ethereum node access"
    echo "  2. Alchemy (https://www.alchemy.com) - Backup provider"
    echo "  3. Etherscan / PolygonScan - For contract verification"
    echo "  4. A wallet with test ETH/MATIC for deployment"
    echo ""
    
    read -p "Do you want to configure smart contracts? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter Infura API Key: " INFURA_API_KEY
        read -p "Enter Alchemy API Key: " ALCHEMY_API_KEY
        read -p "Enter Private Key (NEVER commit this!): " PRIVATE_KEY
        read -p "Enter Etherscan API Key (optional): " ETHERSCAN_API_KEY
        read -p "Enter PolygonScan API Key (optional): " POLYGONSCAN_API_KEY
        
        echo "Setting smart contract secrets..."
        flyctl secrets set \
            INFURA_API_KEY="$INFURA_API_KEY" \
            ALCHEMY_API_KEY="$ALCHEMY_API_KEY" \
            PRIVATE_KEY="$PRIVATE_KEY"
        
        if [ ! -z "$ETHERSCAN_API_KEY" ]; then
            flyctl secrets set ETHERSCAN_API_KEY="$ETHERSCAN_API_KEY"
        fi
        
        if [ ! -z "$POLYGONSCAN_API_KEY" ]; then
            flyctl secrets set POLYGONSCAN_API_KEY="$POLYGONSCAN_API_KEY"
        fi
        
        echo -e "${GREEN}✅ Smart contracts configured${NC}"
    fi
    
    echo ""
}

# Analytics Configuration
configure_analytics() {
    echo -e "${BLUE}📊 Analytics Configuration${NC}"
    echo "=========================="
    echo ""
    echo "Options:"
    echo "  1. Umami (https://umami.is) - Privacy-focused analytics"
    echo "  2. Plausible (https://plausible.io) - Privacy-focused alternative"
    echo "  3. Skip analytics"
    echo ""
    
    read -p "Enter choice (1-3): " choice
    case $choice in
        1)
            read -p "Enter Umami endpoint (https://...): " ANALYTICS_ENDPOINT
            read -p "Enter Umami website ID: " ANALYTICS_WEBSITE_ID
            
            echo "Setting Umami configuration..."
            flyctl config set env VITE_ANALYTICS_ENDPOINT="$ANALYTICS_ENDPOINT" \
                                   VITE_ANALYTICS_WEBSITE_ID="$ANALYTICS_WEBSITE_ID"
            echo -e "${GREEN}✅ Umami configured${NC}"
            ;;
        2)
            echo "Visit https://plausible.io and follow setup instructions"
            echo "Then set: VITE_ANALYTICS_ENDPOINT and VITE_ANALYTICS_WEBSITE_ID"
            ;;
        3)
            echo "Skipping analytics"
            ;;
    esac
    
    echo ""
}

# OAuth Configuration
configure_oauth() {
    echo -e "${BLUE}🔐 OAuth Configuration${NC}"
    echo "====================="
    echo ""
    echo "Current OAuth settings can be found in:"
    echo "  fly.toml (VITE_OAUTH_PORTAL_URL, VITE_APP_ID)"
    echo ""
    
    read -p "Do you want to update OAuth settings? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter OAuth Portal URL: " OAUTH_PORTAL_URL
        read -p "Enter App ID: " APP_ID
        
        echo "Updating fly.toml..."
        # This would require more complex file manipulation
        echo "Please manually update fly.toml with:"
        echo "  VITE_OAUTH_PORTAL_URL = \"$OAUTH_PORTAL_URL\""
        echo "  VITE_APP_ID = \"$APP_ID\""
        echo ""
        echo "Then run: flyctl deploy"
    fi
    
    echo ""
}

# View Secrets
view_secrets() {
    echo -e "${BLUE}🔑 Current Secrets${NC}"
    echo "=================="
    echo ""
    flyctl secrets list
    echo ""
}

# Reset Secrets
reset_secrets() {
    echo -e "${RED}⚠️  Warning: This will remove all custom secrets!${NC}"
    read -p "Are you sure? Type 'yes' to confirm: " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo "Resetting secrets..."
        # Keep only essential secrets
        ESSENTIAL="DATABASE_URL AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_REGION BUCKET_NAME JWT_SECRET STRIPE_SECRET_KEY"
        
        flyctl secrets list | awk '{print $1}' | tail -n +2 | while read secret; do
            if [[ ! $ESSENTIAL =~ $secret ]]; then
                flyctl secrets unset "$secret"
            fi
        done
        
        echo -e "${GREEN}✅ Secrets reset${NC}"
    else
        echo "Cancelled"
    fi
    
    echo ""
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice (1-8): " choice
    
    case $choice in
        1) configure_ipfs ;;
        2) configure_ai ;;
        3) configure_contracts ;;
        4) configure_analytics ;;
        5) configure_oauth ;;
        6) view_secrets ;;
        7) reset_secrets ;;
        8) 
            echo -e "${GREEN}✅ Configuration complete!${NC}"
            echo ""
            echo "Next steps:"
            echo "  1. Review configuration: flyctl secrets list"
            echo "  2. Deploy: flyctl deploy"
            echo "  3. Monitor: flyctl logs"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
done
