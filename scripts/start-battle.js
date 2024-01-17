const { ethers, network, getNamedAccounts, deployments} = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")

const TOKEN_ID_def = 0
const TOKEN_ID_attk = 1
const RANDOM_INT = 4929240890866

let NFTBattleArena, NFTBattleArenaAddress, NFTBattleArenaInstance
let WarriorNft, WarriorNftAddress, WarriorNftInstance

async function startbattle() {
    const { deployer } = await getNamedAccounts()
    const signer = await ethers.getSigner(deployer)
    WarriorNft = await deployments.get("WarriorNft")
    WarriorNftAddress = WarriorNft.address
    WarriorNftInstance = await ethers.getContractAt(
        "WarriorNft",
        WarriorNftAddress,
        signer,
    )
    NFTBattleArena = await deployments.get("NFTBattleArena")
    NFTBattleArenaAddress = NFTBattleArena.address
    NFTBattleArenaInstance = await ethers.getContractAt(
        "NFTBattleArena",
        NFTBattleArenaAddress,
        signer,
    )
    console.log("Approving NFT...")
    const approvalTx = await WarriorNftInstance.approve(NFTBattleArenaAddress, TOKEN_ID_attk)
    await approvalTx.wait(1)
    const approval2Tx = await WarriorNftInstance.approve(NFTBattleArenaAddress, TOKEN_ID_def)
    await approval2Tx.wait(1)
    console.log(`nft with tokenId: ${TOKEN_ID_attk} is attacking ${TOKEN_ID_def}`)
    const terrariaTx = await NFTBattleArenaInstance.checkTerraria()
    // await terrariaTx.wait(1)
    if (terrariaTx == 0){
        const attribute = "speed"
        console.log(`Terraria is chosen: ${terrariaTx}, then ${attribute} matters`)
    } else if (terrariaTx == 1){
        const attribute = "damage"
        console.log(`Terraria is chosen: ${terrariaTx}, then ${attribute} matters`)
    } else if (terrariaTx == 2){
        const attribute = "intelligence"
        console.log(`Terraria is chosen: ${terrariaTx}, then ${attribute} matters`)
    }

    const battleTx = await NFTBattleArenaInstance.startBattle(TOKEN_ID_def, TOKEN_ID_attk, RANDOM_INT)
    await battleTx.wait(1)
    const winnerTx = await NFTBattleArenaInstance.getWinnerTokenId()
    console.log(`Winning NFT is ${winnerTx}`)
    const loserTx = await NFTBattleArenaInstance.getLoserTokenId()
    console.log(`Loser NFT is ${loserTx}`)
    const defHpTx = await NFTBattleArenaInstance.getNFTHP(TOKEN_ID_def)
    const attHpTx = await NFTBattleArenaInstance.getNFTHP(TOKEN_ID_attk)
    console.log(`NFT #${TOKEN_ID_def} has ${defHpTx} HP`)
    console.log(`NFT #${TOKEN_ID_attk} has ${attHpTx} HP`)
    // console.log(airdropTx)
    if (network.config.chainId == 31337) {
        // Moralis has a hard time if you move more than 1 block!
        await moveBlocks(2, (sleepAmount = 1000))
    }
}

startbattle()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
