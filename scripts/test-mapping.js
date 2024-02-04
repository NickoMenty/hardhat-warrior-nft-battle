const { ethers, network, getNamedAccounts, deployments} = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")

const TOKEN_ID = 4
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
    const airdropTx = await NFTBattleArenaInstance.getAttributes(TOKEN_ID)
    // const airdropTxReceipt = airdropTx.wait(1)
    console.log(airdropTx)
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
