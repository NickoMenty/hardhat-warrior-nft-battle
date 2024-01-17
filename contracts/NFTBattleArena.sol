// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error NotOwner();
error NotContractOwner();
error NotApprovedForBattle();
error NotEnoughNFTIsListed();
error RangeOutOfBounds();
error NotListed(uint256 tokenId);

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

    
    constructor(address _nftCollection) {
        i_nftCollection = _nftCollection; 
        i_contract_owner = msg.sender;
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

    function startBattle(uint256 _tokenIdDef, uint256 _tokenIdAtk, uint256 _randomInt) public isListed(_tokenIdDef) isOwner(_tokenIdAtk, msg.sender){
        // Start a battle between two NFTs
        IERC721 nft = IERC721(i_nftCollection);
        if (nft.getApproved(_tokenIdAtk) != address(this)) {
            revert NotApprovedForBattle();
        }
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
        // ... Add more else if statements for other logicIds as needed

        winner = isFirstWinner ? nft.ownerOf(tokenId1) : nft.ownerOf(tokenId2);
        winnerTokenId = isFirstWinner ? tokenId1 : tokenId2;
        loserTokenId = isFirstWinner ? tokenId2 : tokenId1;
    }

    function executeBattle(uint256 _logicId, uint256 _tokenIdDef, uint256 _tokenIdAtk) private {
        (s_winner, s_winningTokenId, s_loserTokenId) = determineWinner(_tokenIdDef, _tokenIdAtk, _logicId);

        NFTAttributes storage loserAttributes = nftAttributes[s_loserTokenId];
        if (loserAttributes.hp > 0) {
            loserAttributes.hp--;
        }

        if (loserAttributes.hp == 0) {
            burnItem(s_loserTokenId);
        }
        emit WinnerPickerd(s_winner, s_winningTokenId);
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
    
}