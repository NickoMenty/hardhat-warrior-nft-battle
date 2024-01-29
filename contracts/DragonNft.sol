// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error DragonNft__AlreadyInitialized();
error DragonNft__NeedMoreETHSent();
error DragonNft__RangeOutOfBounds();
error DragonNft__TransferFailed();
error DragonNft__MaxSupplyReached();
error DragonNft__InvalidAirdrop();
error DragonNft__SoldOut();
// error DragonNft__NotWhitelisted();


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

contract DragonNft is ERC721URIStorage, Ownable {

    // NFT Variables
    using Strings for uint256;
    uint256 private immutable i_mintFee;
    uint64 private s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    uint256 private immutable i_maxSupply;
    string[] internal s_genTokenUris;
    bool private s_initialized;
    bool public revealed = false;
    string public constant NOT_REVEALED_URI = "https://ipfs.io/ipfs/QmT7HRAdGoP4ppZwQXAkr2R1vVzbRGuyDgs59EWBWMHQch";
    // mapping(address => bool) public whitelisted;
    IBlast immutable i_blast;

    // Events
    event NftMinted(uint256 tokenId, address minter);
    event TokensAirdropped(uint256 numRecipients, uint256 numTokens);

    constructor(
        uint256 mintFee,
        uint256 maxSupply
    ) ERC721 ("Bragon", "BRAG") {
        i_mintFee = mintFee;
        s_tokenCounter = 0;
        i_maxSupply = maxSupply;
        i_blast = IBlast(0x4300000000000000000000000000000000000002);
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableYield();
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableGas();
    }

    function mintNft() public payable {
        if (s_tokenCounter >= i_maxSupply) {
            revert DragonNft__MaxSupplyReached(); // Check for max supply
        }
        if (msg.value < i_mintFee) {
            revert DragonNft__NeedMoreETHSent();
        }
        // if (whitelisted[msg.sender] != true) {
        //   revert DragonNft__NotWhitelisted();
        // }
        
        address genOwner = msg.sender;
        uint256 newItemId = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1;
        _safeMint(genOwner, newItemId);
        emit NftMinted(newItemId, genOwner);   
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (_exists(tokenId) == false){
        revert DragonNft__RangeOutOfBounds();
    }
    
    if(revealed == false) {
        return NOT_REVEALED_URI;
    }

    string memory currentBaseURI = Dragon_BaseURI(tokenId);
    return currentBaseURI;
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert DragonNft__TransferFailed();
        }
    }

    function airdropToken(
        uint64[] calldata quantity,
        address[] calldata recipients
    ) external onlyOwner {
        uint256 numRecipients = recipients.length; 
        uint256 totalAirdropped; 
        if (numRecipients != quantity.length) revert DragonNft__InvalidAirdrop(); 

        for (uint256 i = 0; i < numRecipients; ) { 
            for (uint256 k = 0; k < quantity[i]; ) { 
                uint64 updatedAmountMinted = s_tokenCounter + 1;
                if (updatedAmountMinted > i_maxSupply) {
                    revert DragonNft__SoldOut();
                }

                s_tokenCounter = updatedAmountMinted;
                totalAirdropped += 1;

                uint256 newItemId = s_tokenCounter;
                _safeMint(recipients[i], newItemId);
                _setTokenURI(newItemId, s_genTokenUris[s_tokenCounter]);

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

    /* Reveal and Whitelist */
    function reveal() public onlyOwner {
        revealed = true;
    }

    // function whitelistUser(address _user) public onlyOwner {
    //     whitelisted[_user] = true;
    // }
    
    // function removeWhitelistUser(address _user) public onlyOwner {
    //     whitelisted[_user] = false;
    // }

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

    function Dragon_BaseURI(uint256 index) internal view virtual returns (string memory) {
        return s_genTokenUris[index];
    }
    
}