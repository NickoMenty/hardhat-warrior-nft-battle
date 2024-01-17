const { ethers, network, getNamedAccounts, deployments} = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")
const fs = require("fs")
const path = require("path")

const metadataLocation = "./warriorsNfts.json"

let NFTBattleArena, NFTBattleArenaAddress, NFTBattleArenaInstance

async function setattributesforall() {
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
    const metadataJson = JSON.parse(fs.readFileSync(metadataLocation, "utf8"))
    let i = 0;  // For loop initializer
    while (i < 10)  // For loop condition (and the actual loop)
    {   
        let tokenUri = metadataJson[i]
        let tokenId = i
        
        const speedVariable = tokenUri.attributes[0].value
        console.log(`Speed value ${speedVariable} for tokenID ${i}`)
        const damageVariable = tokenUri.attributes[1].value
        console.log(`Damage value ${damageVariable} for tokenID ${i}`)
        const intelligenceVariable = tokenUri.attributes[2].value
        console.log(`Intelligence value ${intelligenceVariable} for tokenID ${i}`)
        const hpVariable = tokenUri.attributes[3].value
        console.log(`HP value ${hpVariable} for tokenID ${i}`)
        let attributes = {
            speed: speedVariable,
            damage: damageVariable,
            intelligence: intelligenceVariable,
            hp: hpVariable
        }
        const airdropTx = await NFTBattleArenaInstance.setNFTAttributes(tokenId, attributes)
        // console.log(airdropTx)
        
        i++
    } 
    // const airdropTxReceipt = airdropTx.wait(1)
    if (network.config.chainId == 31337) {
        // Moralis has a hard time if you move more than 1 block!
        await moveBlocks(2, (sleepAmount = 1000))
    }
    
}

setattributesforall()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
