const { ethers, network, getNamedAccounts, deployments} = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")

const TOKEN_ID = 0
let NFTBattleArena, NFTBattleArenaAddress, NFTBattleArenaInstance

async function testmapping() {
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
    const listednftTx = await NFTBattleArenaInstance.getlistedNFT(TOKEN_ID)
    // const airdropTxReceipt = airdropTx.wait(1)
    console.log(listednftTx)
    const airdropTx = await NFTBattleArenaInstance.getOwnerOf(TOKEN_ID)
    // const airdropTxReceipt = airdropTx.wait(1)
    console.log(airdropTx)
    const airdrop2Tx = await NFTBattleArenaInstance.areEqual(TOKEN_ID)
    // const airdropTxReceipt = airdropTx.wait(1)
    console.log(airdrop2Tx)
    if (network.config.chainId == 31337) {
        // Moralis has a hard time if you move more than 1 block!
        await moveBlocks(2, (sleepAmount = 1000))
    }
}

testmapping()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
