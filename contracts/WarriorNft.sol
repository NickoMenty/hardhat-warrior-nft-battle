// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error WarriorNft__AlreadyInitialized();
error WarriorNft__NeedMoreETHSent();
error WarriorNft__RangeOutOfBounds();
error WarriorNft__TransferFailed();
error WarriorNft__MaxSupplyReached();
error WarriorNft__InvalidAirdrop();
error WarriorNft__SoldOut();

contract WarriorNft is ERC721URIStorage, Ownable {

    // NFT Variables
    uint256 private immutable i_mintFee;
    uint64 private s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    uint256 private immutable i_maxSupply;
    string[] internal s_genTokenUris;
    bool private s_initialized;

    // Events
    event NftMinted(uint256 tokenId, address minter);
    event TokensAirdropped(uint256 numRecipients, uint256 numTokens);

    mapping(uint256 => uint256) public nft_health;

    constructor(
        uint256 mintFee,
        string[10] memory genTokenUris,
        uint256 maxSupply
    ) ERC721 ("Warrior", "WAIO") {
        _initializeContract(genTokenUris);
        i_mintFee = mintFee;
        s_tokenCounter = 0;
        i_maxSupply = maxSupply;
    }

    function mintNft() public payable {
        if (s_tokenCounter >= i_maxSupply) {
            revert WarriorNft__MaxSupplyReached(); // Check for max supply
        }
        if (msg.value < i_mintFee) {
            revert WarriorNft__NeedMoreETHSent();
        }
        address genOwner = msg.sender;
        uint256 newItemId = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1;
        _safeMint(genOwner, newItemId);
        _setTokenURI(newItemId, s_genTokenUris[s_tokenCounter]);
        nft_health[newItemId] = 6;
        emit NftMinted(newItemId, genOwner);
        
    }

    function _initializeContract(string[10] memory genTokenUris) private {
        if (s_initialized) {
            revert WarriorNft__AlreadyInitialized();
        }
        s_genTokenUris = genTokenUris;
        s_initialized = true;
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert WarriorNft__TransferFailed();
        }
    }

    function airdropToken(
        uint64[] calldata quantity,
        address[] calldata recipients
    ) external onlyOwner {
        uint256 numRecipients = recipients.length; 
        uint256 totalAirdropped; 
        if (numRecipients != quantity.length) revert WarriorNft__InvalidAirdrop(); 

        for (uint256 i = 0; i < numRecipients; ) { 
            for (uint256 k = 0; k < quantity[i]; ) { 
                uint64 updatedAmountMinted = s_tokenCounter + 1;
                if (updatedAmountMinted > i_maxSupply) {
                    revert WarriorNft__SoldOut();
                }

                // airdrops are not subject to the per-wallet mint limits,
                // but we track how much is minted
                s_tokenCounter = updatedAmountMinted;
                totalAirdropped += 1;

                uint256 newItemId = s_tokenCounter;
                _safeMint(recipients[i], newItemId);
                _setTokenURI(newItemId, s_genTokenUris[s_tokenCounter]);

                // numRecipients has a maximum value of 2^256 - 1
                unchecked {
                    ++k;
                }
            }
            unchecked {
                    ++i;
            }
        }

        emit TokensAirdropped(numRecipients, totalAirdropped);
    }

    function getMintFee() public view returns (uint256) {
        return i_mintFee;
    }

    function getgenTokenUris(uint256 index) public view returns (string memory) {
        return s_genTokenUris[index];
    }

    function getInitialized() public view returns (bool) {
        return s_initialized;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
    
}