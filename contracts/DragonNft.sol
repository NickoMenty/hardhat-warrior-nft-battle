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
error DragonNft__WrongURIList();
error DragonNft_NotInitialized();
error DragonNft__NotWhitelisted();
error DragonNft_NotOpen();
error DragonNft_AlreadyOpen();
error DragonNft__AlreadyMintedInWhitelist();
error DragonNft__AlreadyMintedInPublic();


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

    enum MintState {
        CLOSED,
        WHITELIST,
        PUBLIC
    } // uint256 0 = closed, 1 = whitelist, 2 = public

    // NFT Variables
    using Strings for uint256;
    uint256 private s_mintFee;
    uint64 private s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    uint256 private s_maxSupply;
    string[] internal s_genTokenUris;
    bool private s_initializedURIs = false;
    bool private s_initializedFeeAndSupply = false;
    bool public s_revealed = false;
    string public constant NOT_REVEALED_URI = "https://ipfs.io/ipfs/QmT7HRAdGoP4ppZwQXAkr2R1vVzbRGuyDgs59EWBWMHQch";
    mapping(address => bool) public whitelisted;
    bool public s_whitelistMintOpen = false;
    bool public s_PublicMintOpen = false;
    mapping(address => uint256) public mintCountWhitelist;
    uint256 public s_whitelistMintAmount;
    mapping(address => uint256) public mintCountPublic;
    uint256 public s_publicMintAmount;
    bool private s_initializedMintAmount = false;
    MintState public s_mintState;
    IBlast immutable i_blast;

    // Events
    event NftMinted(uint256 tokenId, address minter);
    event TokensAirdropped(uint256 numRecipients, uint256 numTokens);

    constructor(
        uint256 mintFee,
        uint256 maxSupply
    ) ERC721 ("Bragon", "BRAG") {
        s_mintState = MintState.CLOSED;
        s_mintFee = mintFee;
        s_tokenCounter = 0;
        s_whitelistMintAmount = 1;
        s_publicMintAmount = 1;
        s_maxSupply = maxSupply;
        i_blast = IBlast(0x4300000000000000000000000000000000000002);
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableYield();
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableGas();
    }

    function mintNft() public payable {
        if (s_mintState == MintState.CLOSED) {
            revert DragonNft_NotOpen();
        }
        if (!s_initializedFeeAndSupply){
            revert DragonNft_NotInitialized();
        }
        if (s_tokenCounter >= s_maxSupply) {
            revert DragonNft__MaxSupplyReached(); 
        }
        if (msg.value < s_mintFee) {
            revert DragonNft__NeedMoreETHSent();
        }
        if (s_mintState == MintState.WHITELIST) {
            if (whitelisted[msg.sender] != true) {
                revert DragonNft__NotWhitelisted();
            }
            if (mintCountWhitelist[msg.sender] >= s_whitelistMintAmount) {
                revert DragonNft__AlreadyMintedInWhitelist();
            }
            mintCountWhitelist[msg.sender]++;
        } else if (s_mintState == MintState.PUBLIC) {
            if (mintCountPublic[msg.sender] >= s_publicMintAmount) {
                revert DragonNft__AlreadyMintedInPublic(); 
            }
            mintCountPublic[msg.sender]++;
        }
        
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
    
    if(s_revealed == false) {
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
        if (!s_initializedFeeAndSupply){
            revert DragonNft_NotInitialized();
        } 
        if (numRecipients != quantity.length) revert DragonNft__InvalidAirdrop(); 

        for (uint256 i = 0; i < numRecipients; ) { 
            for (uint256 k = 0; k < quantity[i]; ) { 
                uint64 updatedAmountMinted = s_tokenCounter + 1;
                if (updatedAmountMinted > s_maxSupply) {
                    revert DragonNft__SoldOut();
                }

                s_tokenCounter = updatedAmountMinted;
                totalAirdropped += 1;

                uint256 newItemId = s_tokenCounter;
                _safeMint(recipients[i], newItemId);

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

    /* SetUp to OpenMint */
    // step 0 - set MaxSupply and set MintFee
    function _initializeContract(uint256 maxSupply, uint256 mintFee) public onlyOwner{
        if (s_initializedFeeAndSupply) {
            revert DragonNft__AlreadyInitialized();
        }
        s_mintFee = mintFee;
        s_maxSupply = maxSupply;
        s_initializedFeeAndSupply = true;
    }
    // step 1 - set Mint Amount for WL and Public
    function _initializeMintAmount(uint256 whitelistAmount, uint256 publicAmount) public onlyOwner{
        if (s_initializedMintAmount) {
            revert DragonNft__AlreadyInitialized();
        }
        s_whitelistMintAmount = whitelistAmount;
        s_publicMintAmount = publicAmount;
        s_initializedMintAmount = true;
    }

    // Step 2 - add and remove whitelists
    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }
    
    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }
    // step 3 - open mint for whitelists
    function openWhitelistMint() public onlyOwner {
        if (s_mintState == MintState.WHITELIST) {
            revert DragonNft_AlreadyOpen();
        }
        s_mintState = MintState.WHITELIST;
    }
    // step 4 - open mint for public
    function openPublicMint() public onlyOwner {
        if (s_mintState == MintState.PUBLIC) {
            revert DragonNft_AlreadyOpen();
        }
        s_mintState = MintState.PUBLIC;
    }

    /* Reveal */
    // Reveal step 1 - pass URIs
    function _initializeContractURIs(string[] memory genTokenUris) public onlyOwner{
        if (s_initializedURIs) {
            revert DragonNft__AlreadyInitialized();
        }
        if (genTokenUris.length != s_maxSupply) {
            revert DragonNft__WrongURIList();
        }
        s_genTokenUris = genTokenUris;
        s_initializedURIs = true;
    }

    // Reveal step 2 - reveal URIs
    function reveal() public onlyOwner {
        s_revealed = true;
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
        return s_mintFee;
    }

    function getgenTokenUris(uint256 index) public view returns (string memory) {
        return s_genTokenUris[index];
    }

    function getInitialized() public view returns (bool) {
        return s_initializedURIs;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getMintState() public view returns (MintState) {
        return s_mintState;
    }

    function Dragon_BaseURI(uint256 index) internal view virtual returns (string memory) {
        return s_genTokenUris[index];
    }
    
}