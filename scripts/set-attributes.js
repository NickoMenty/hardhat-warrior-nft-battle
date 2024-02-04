const { ethers, network, getNamedAccounts, deployments} = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")
const fs = require("fs")
const path = require("path")

const TOKEN_ID = 0
const ATTRIBUTES = {
    speed: 10,
    damage: 100,
    intelligence: 10
}

let NFTBattleArena, NFTBattleArenaAddress, NFTBattleArenaInstance

async function setattributes() {
    const { deployer } = await getNamedAccounts()
    const signer = await ethers.getSigner(deployer)
    NFTBattleArena = await deployments.get("NFTBattleArena")
    NFTBattleArenaAddress = NFTBattleArena.address
    NFTBattleArenaInstance = await ethers.getContractAt(
        "NFTBattleArena",
        NFTBattleArenaAddress,
        signer,
    )
    console.log("setting attributes")
    const attributeTx = await NFTBattleArenaInstance.setNFTAttributes(TOKEN_ID, ATTRIBUTES)
    console.log(attributeTx)
    // const airdropTxReceipt = airdropTx.wait(1)
    
    if (network.config.chainId == 31337) {
        // Moralis has a hard time if you move more than 1 block!
        await moveBlocks(2, (sleepAmount = 1000))
    }
}

setattributes()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
