// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error WarriorNft__AlreadyInitialized();
error WarriorNft__NeedMoreETHSent();
error WarriorNft__RangeOutOfBounds();
error WarriorNft__TransferFailed();
error WarriorNft__MaxSupplyReached();
error WarriorNft__InvalidAirdrop();
error WarriorNft__SoldOut();


enum YieldMode {
    AUTOMATIC,
    VOID,
    CLAIMABLE
}

enum GasMode {
    VOID,
    CLAIMABLE 
}

interface IBlast{
    // configure
    function configureContract(address contractAddress, YieldMode _yield, GasMode gasMode, address governor) external;
    function configure(YieldMode _yield, GasMode gasMode, address governor) external;

    // base configuration options
    function configureClaimableYield() external;
    function configureClaimableYieldOnBehalf(address contractAddress) external;
    function configureAutomaticYield() external;
    function configureAutomaticYieldOnBehalf(address contractAddress) external;
    function configureVoidYield() external;
    function configureVoidYieldOnBehalf(address contractAddress) external;
    function configureClaimableGas() external;
    function configureClaimableGasOnBehalf(address contractAddress) external;
    function configureVoidGas() external;
    function configureVoidGasOnBehalf(address contractAddress) external;
    function configureGovernor(address _governor) external;
    function configureGovernorOnBehalf(address _newGovernor, address contractAddress) external;

    // claim yield
    function claimYield(address contractAddress, address recipientOfYield, uint256 amount) external returns (uint256);
    function claimAllYield(address contractAddress, address recipientOfYield) external returns (uint256);

    // claim gas
    function claimAllGas(address contractAddress, address recipientOfGas) external returns (uint256);
    function claimGasAtMinClaimRate(address contractAddress, address recipientOfGas, uint256 minClaimRateBips) external returns (uint256);
    function claimMaxGas(address contractAddress, address recipientOfGas) external returns (uint256);
    function claimGas(address contractAddress, address recipientOfGas, uint256 gasToClaim, uint256 gasSecondsToConsume) external returns (uint256);

    // read functions
    function readClaimableYield(address contractAddress) external view returns (uint256);
    function readYieldConfiguration(address contractAddress) external view returns (uint8);
    function readGasParams(address contractAddress) external view returns (uint256 etherSeconds, uint256 etherBalance, uint256 lastUpdated, GasMode);
}

contract WarriorNft is ERC721URIStorage, Ownable {

    // NFT Variables
    uint256 private immutable i_mintFee;
    uint64 private s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    uint256 private immutable i_maxSupply;
    string[] internal s_genTokenUris;
    bool private s_initialized;
    IBlast immutable i_blast;

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
        i_blast = IBlast(0x4300000000000000000000000000000000000002);
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableYield();
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableGas();
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

    /* Blast functions */
    function claimYield(address recipient, uint256 amount) external onlyOwner{
		IBlast(0x4300000000000000000000000000000000000002).claimYield(address(this), recipient, amount);
    }
    function claimAllYield(address recipient) external onlyOwner{
		IBlast(0x4300000000000000000000000000000000000002).claimAllYield(address(this), recipient);
    }
    function claimAllGas(address recipient) external onlyOwner{
        // To claim all gas, regardless of tax
		IBlast(0x4300000000000000000000000000000000000002).claimAllGas(address(this), recipient);
    }
    function claimMaxGas(address recipient) external onlyOwner{
        // To only claim fully vested gas (i.e. at a 0% tax rate)
		IBlast(0x4300000000000000000000000000000000000002).claimAllGas(address(this), recipient);
    }

    /* Blast view functions */
    function readClaimableYield() public view returns (uint256) {
        return IBlast(0x4300000000000000000000000000000000000002).readClaimableYield(address(this));
    }

    function readGasParams() public view returns (uint256 etherSeconds, uint256 etherBalance, uint256 lastUpdated, GasMode) {
        return IBlast(0x4300000000000000000000000000000000000002).readGasParams(address(this));
    }

    /* View and Pure functions */

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