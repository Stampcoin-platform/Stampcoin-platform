// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @title StampCoinNFT
 * @dev ERC721 NFT contract for authenticated digital stamp collectibles
 * Features:
 * - Authentication tracking on-chain
 * - Provenance recording
 * - Royalty enforcement (ERC2981)
 * - Physical stamp linking
 * - Batch minting support
 */
contract StampCoinNFT is ERC721, ERC721URIStorage, ERC721Burnable, AccessControl, IERC2981 {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant AUTHENTICATOR_ROLE = keccak256("AUTHENTICATOR_ROLE");
    
    Counters.Counter private _tokenIdCounter;

    // Royalty configuration (basis points, e.g., 500 = 5%)
    uint96 public constant ROYALTY_FEE = 500; // 5%
    address public royaltyReceiver;

    // Authentication and provenance data
    struct StampData {
        string physicalStampId;      // Links to physical stamp
        bool isAuthenticated;         // Authentication status
        address authenticatedBy;      // Authenticator address
        uint256 authenticatedAt;      // Timestamp
        uint8 confidenceScore;        // 0-100
        string certificateUri;        // IPFS URI of certificate
    }

    struct ProvenanceRecord {
        address from;
        address to;
        uint256 timestamp;
        string notes;
    }

    // Mappings
    mapping(uint256 => StampData) public stampData;
    mapping(uint256 => ProvenanceRecord[]) public provenance;
    mapping(string => uint256) public physicalStampToToken;
    mapping(uint256 => bool) public isAuthenticated;

    // Events
    event StampMinted(
        uint256 indexed tokenId,
        address indexed to,
        string physicalStampId,
        string tokenURI
    );
    
    event StampAuthenticated(
        uint256 indexed tokenId,
        address indexed authenticator,
        uint8 confidenceScore,
        string certificateUri
    );
    
    event ProvenanceRecorded(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        string notes
    );

    constructor(
        address _royaltyReceiver
    ) ERC721("StampCoin Digital Collectibles", "STAMP") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(AUTHENTICATOR_ROLE, msg.sender);
        royaltyReceiver = _royaltyReceiver;
    }

    /**
     * @dev Mint a new stamp NFT
     * @param to Recipient address
     * @param tokenURI IPFS URI for metadata
     * @param physicalStampId Unique identifier linking to physical stamp
     */
    function mintStamp(
        address to,
        string memory tokenURI,
        string memory physicalStampId
    ) public onlyRole(MINTER_ROLE) returns (uint256) {
        require(bytes(physicalStampId).length > 0, "Physical ID required");
        require(physicalStampToToken[physicalStampId] == 0, "Physical stamp already minted");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        
        stampData[tokenId] = StampData({
            physicalStampId: physicalStampId,
            isAuthenticated: false,
            authenticatedBy: address(0),
            authenticatedAt: 0,
            confidenceScore: 0,
            certificateUri: ""
        });
        
        physicalStampToToken[physicalStampId] = tokenId;
        
        // Record initial provenance
        provenance[tokenId].push(ProvenanceRecord({
            from: address(0),
            to: to,
            timestamp: block.timestamp,
            notes: "Initial mint"
        }));
        
        emit StampMinted(tokenId, to, physicalStampId, tokenURI);
        return tokenId;
    }

    /**
     * @dev Batch mint multiple stamps (gas efficient)
     */
    function batchMintStamps(
        address[] memory recipients,
        string[] memory tokenURIs,
        string[] memory physicalStampIds
    ) external onlyRole(MINTER_ROLE) returns (uint256[] memory) {
        require(
            recipients.length == tokenURIs.length && 
            recipients.length == physicalStampIds.length,
            "Array length mismatch"
        );
        
        uint256[] memory tokenIds = new uint256[](recipients.length);
        
        for (uint256 i = 0; i < recipients.length; i++) {
            tokenIds[i] = mintStamp(recipients[i], tokenURIs[i], physicalStampIds[i]);
        }
        
        return tokenIds;
    }

    /**
     * @dev Authenticate a stamp NFT
     */
    function authenticateStamp(
        uint256 tokenId,
        uint8 confidenceScore,
        string memory certificateUri
    ) external onlyRole(AUTHENTICATOR_ROLE) {
        require(_exists(tokenId), "Token does not exist");
        require(confidenceScore <= 100, "Score must be 0-100");
        require(!stampData[tokenId].isAuthenticated, "Already authenticated");
        
        stampData[tokenId].isAuthenticated = true;
        stampData[tokenId].authenticatedBy = msg.sender;
        stampData[tokenId].authenticatedAt = block.timestamp;
        stampData[tokenId].confidenceScore = confidenceScore;
        stampData[tokenId].certificateUri = certificateUri;
        isAuthenticated[tokenId] = true;
        
        emit StampAuthenticated(tokenId, msg.sender, confidenceScore, certificateUri);
    }

    /**
     * @dev Record provenance entry
     */
    function recordProvenance(
        uint256 tokenId,
        string memory notes
    ) external {
        require(_exists(tokenId), "Token does not exist");
        require(
            ownerOf(tokenId) == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Not authorized"
        );
        
        provenance[tokenId].push(ProvenanceRecord({
            from: address(0),
            to: ownerOf(tokenId),
            timestamp: block.timestamp,
            notes: notes
        }));
        
        emit ProvenanceRecorded(tokenId, address(0), ownerOf(tokenId), notes);
    }

    /**
     * @dev Override transfer to record provenance automatically
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        
        if (from != address(0) && to != address(0)) {
            provenance[tokenId].push(ProvenanceRecord({
                from: from,
                to: to,
                timestamp: block.timestamp,
                notes: "Transfer"
            }));
            
            emit ProvenanceRecorded(tokenId, from, to, "Transfer");
        }
    }

    /**
     * @dev Get provenance history for a token
     */
    function getProvenance(uint256 tokenId) external view returns (ProvenanceRecord[] memory) {
        require(_exists(tokenId), "Token does not exist");
        return provenance[tokenId];
    }

    /**
     * @dev Get stamp data
     */
    function getStampData(uint256 tokenId) external view returns (StampData memory) {
        require(_exists(tokenId), "Token does not exist");
        return stampData[tokenId];
    }

    /**
     * @dev Check if a physical stamp has been minted
     */
    function isPhysicalStampMinted(string memory physicalStampId) external view returns (bool) {
        return physicalStampToToken[physicalStampId] != 0;
    }

    /**
     * @dev Get token ID by physical stamp ID
     */
    function getTokenByPhysicalId(string memory physicalStampId) external view returns (uint256) {
        uint256 tokenId = physicalStampToToken[physicalStampId];
        require(tokenId != 0, "Physical stamp not minted");
        return tokenId;
    }

    /**
     * @dev Update royalty receiver
     */
    function setRoyaltyReceiver(address _royaltyReceiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        royaltyReceiver = _royaltyReceiver;
    }

    /**
     * @dev ERC2981 royalty info
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address, uint256) {
        require(_exists(tokenId), "Token does not exist");
        uint256 royaltyAmount = (salePrice * ROYALTY_FEE) / 10000;
        return (royaltyReceiver, royaltyAmount);
    }

    // Required overrides
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage, AccessControl, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}
