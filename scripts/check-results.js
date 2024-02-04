const { ethers, network, getNamedAccounts, deployments} = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")

let NFTBattleArena, NFTBattleArenaAddress, NFTBattleArenaInstance

async function checkresults() {
    const { deployer } = await getNamedAccounts()
    const signer = await ethers.getSigner(deployer)
    NFTBattleArena = await deployments.get("NFTBattleArena")
    NFTBattleArenaAddress = NFTBattleArena.address
    NFTBattleArenaInstance = await ethers.getContractAt(
        "NFTBattleArena",
        NFTBattleArenaAddress,
        signer,
    )
    console.log("asking fro map...")
    const winnerTx = await NFTBattleArenaInstance.getWinnerTokenId()
    console.log(`Winning NFT is ${winnerTx}`)
    const loserTx = await NFTBattleArenaInstance.getLoserTokenId()
    console.log(`Loser NFT is ${loserTx}`)
    if (network.config.chainId == 31337) {
        // Moralis has a hard time if you move more than 1 block!
        await moveBlocks(2, (sleepAmount = 1000))
    }
}

checkresults()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
