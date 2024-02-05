// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error NotOwner();
error NotContractOwner();
error NotApprovedForBattle();
error NotEnoughNFTIsListed();
error RangeOutOfBounds();
error NotListed(uint256 tokenId);


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


contract NFTBattleArena is Ownable{
    // IERC721 public nftCollection;

    enum Terraria {
        DESERT,
        MOUNTAIN,
        VALLEY
    }

    address private immutable i_nftCollection;
    address private immutable i_contract_owner;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    address public s_winner;
    uint256 public s_loserTokenId;
    uint256 public s_winningTokenId;
    address public immutable burnAddress = 0x000000000000000000000000000000000000dEaD;
    Terraria public recTerraria;
    IBlast immutable i_blast;

    
    constructor(address _nftCollection) {
        i_nftCollection = _nftCollection; 
        i_contract_owner = msg.sender;
        i_blast = IBlast(0x4300000000000000000000000000000000000002);
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableYield();
        IBlast(0x4300000000000000000000000000000000000002).configureClaimableGas();
    }

    struct NFTAttributes {
        uint256 speed;
        uint256 damage;
        uint256 intelligence;
        uint256 hp;
    }

    struct Battle {
        uint256 nft1Id;
        uint256 nft2Id;
        uint256 startTime;
        bool isFinished;
    }

    event ItemListed(
        address indexed owner,
        uint256 indexed tokenId
    );

    event ItemCanceled(
        address indexed owner,
        uint256 indexed tokenId
    );

    event TerrariaChosen(
        Terraria indexed terraria
    );

    event WinnerPickerd(
        address indexed owner,
        uint256 indexed tokenId
    );

    event ItemBurned(
        address indexed owner,
        address indexed burnaddress,
        uint256 indexed tokenId
    );

    Battle[] public battles;

    mapping(uint256 => NFTAttributes) public nftAttributes;
    mapping(uint256 => address) public nftlisted;
    mapping(uint256 => uint256) public nftWins;
    

    modifier isOwner(
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(i_nftCollection);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert NotOwner();
        }
        _;
    }

    modifier isListed(uint256 tokenId) {
        IERC721 nft = IERC721(i_nftCollection);
        address owner = nft.ownerOf(tokenId);
        if (nftlisted[tokenId] != owner) {
            revert NotListed(tokenId);
        }
        _;
    }

    function setNFTAttributes(uint256 tokenId, NFTAttributes calldata _attributes) public onlyOwner {
        // Set NFT attributes
        // By using Chainlink we somehow read attributes and store them here
        NFTAttributes storage nftAttribute = nftAttributes[tokenId];

        // Copy each field from the calldata struct to the storage struct
        nftAttribute.speed = _attributes.speed;
        nftAttribute.damage = _attributes.damage;
        nftAttribute.intelligence = _attributes.intelligence;
        nftAttribute.hp = _attributes.hp;
    }

    function random() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
        tx.origin,
        blockhash(block.number - 1),
        block.timestamp
        )));
    }

    function listNFTForBattle(uint256 tokenId) public isOwner(tokenId, msg.sender){
        // List an NFT for battle
        IERC721 nft = IERC721(i_nftCollection);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NotApprovedForBattle();
        }
        nftlisted[tokenId] = msg.sender;
        emit ItemListed(msg.sender, tokenId);
    }

    function unlistNFTFromBattle(uint256 tokenId) public isOwner(tokenId, msg.sender){
        // Unlist an NFT from battle
        delete (nftlisted[tokenId]);
        emit ItemCanceled(msg.sender, tokenId);
    }

    function burnItem(uint256 tokenId)
        public
    {
        delete (nftlisted[tokenId]);
        IERC721 nft = IERC721(i_nftCollection);
        address owner = nft.ownerOf(tokenId);
        IERC721(i_nftCollection).safeTransferFrom(owner, burnAddress, tokenId);
        emit ItemBurned(owner, burnAddress, tokenId);
    }

    function startBattle(uint256 _tokenIdDef, uint256 _tokenIdAtk) public isListed(_tokenIdDef) /* isListed(_tokenIdAtk) */ isOwner(_tokenIdAtk, msg.sender){
        // Start a battle between two NFTs
        IERC721 nft = IERC721(i_nftCollection);
        if (nft.getApproved(_tokenIdAtk) != address(this)) {
            revert NotApprovedForBattle();
        }
        uint256 _randomInt = random();
        uint256 moddedRng = _randomInt % MAX_CHANCE_VALUE;
        recTerraria = getTerrariaFromModdedRng(moddedRng);
        emit TerrariaChosen(recTerraria);
        executeBattle(uint256(recTerraria), _tokenIdDef, _tokenIdAtk);
              

    }
    function getChanceArray() internal pure returns (uint256[3] memory) {
        return [uint256(33), uint256(66), uint256(MAX_CHANCE_VALUE)];
    }
    
    function getTerrariaFromModdedRng(uint256 moddedRng) internal pure returns (Terraria) {
        uint256 cumulativeSum = 0;
        uint256[3] memory TerrariaChance = getChanceArray();
        for (uint256 i = 0; i < TerrariaChance.length; i++) {
                // DESERT = 0 - 33 = 33  (33%)
                // MOUNTAINS = 34-66 = 66  (33%)
                // VALLEY = 66+ = 99 (33%)
            if (moddedRng >= cumulativeSum && moddedRng < TerrariaChance[i]) {
                return Terraria(i);
            }
            cumulativeSum = TerrariaChance[i];
        }
        revert RangeOutOfBounds();
    }

    function determineWinner(uint256 tokenId1, uint256 tokenId2, uint256 logicId) internal view returns (address winner, uint256 winnerTokenId, uint256 loserTokenId) {
        IERC721 nft = IERC721(i_nftCollection);
        bool isFirstWinner;

        if (logicId == 0) {
            isFirstWinner = nftAttributes[tokenId1].speed > nftAttributes[tokenId2].speed;
        } else if (logicId == 1) {
            isFirstWinner = nftAttributes[tokenId1].damage > nftAttributes[tokenId2].damage;
        } else if (logicId == 2) {
            isFirstWinner = nftAttributes[tokenId1].intelligence > nftAttributes[tokenId2].intelligence;
        }

        winner = isFirstWinner ? nft.ownerOf(tokenId1) : nft.ownerOf(tokenId2);
        winnerTokenId = isFirstWinner ? tokenId1 : tokenId2;
        loserTokenId = isFirstWinner ? tokenId2 : tokenId1;
    }

    function executeBattle(uint256 _logicId, uint256 _tokenIdDef, uint256 _tokenIdAtk) private {
        (s_winner, s_winningTokenId, s_loserTokenId) = determineWinner(_tokenIdDef, _tokenIdAtk, _logicId);

        nftWins[s_winningTokenId]++;

        NFTAttributes storage loserAttributes = nftAttributes[s_loserTokenId];
        if (loserAttributes.hp > 0) {
            loserAttributes.hp--;
        }

        if (loserAttributes.hp == 0) {
            burnItem(s_loserTokenId);
        }
        emit WinnerPickerd(s_winner, s_winningTokenId);
    }

    /* Blast fynctions */
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

    /* Blast view fynctions */
    function readClaimableYield() public view returns (uint256) {
        return IBlast(0x4300000000000000000000000000000000000002).readClaimableYield(address(this));
    }

    function readGasParams() public view returns (uint256 etherSeconds, uint256 etherBalance, uint256 lastUpdated, GasMode) {
        return IBlast(0x4300000000000000000000000000000000000002).readGasParams(address(this));
    }



    function getAttributes(uint256 _tokenId) public view returns (NFTAttributes memory) {
        return nftAttributes[_tokenId];
    }

    function getWinnerTokenId() public view returns (uint256) {
        return s_winningTokenId;
    }
    function getLoserTokenId() public view returns (uint256) {
        return s_loserTokenId;
    }
    function checkTerraria() public view returns (uint256) {
        return uint256(recTerraria);
    }
    function getNFTWins(uint256 _tokenId) public view returns (uint256) {
    return nftWins[_tokenId];
    }
    
}