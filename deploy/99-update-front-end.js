const {
    frontEndContractsFile,
    frontEndAbiLocation
} = require("../helper-hardhat-config")
require("dotenv").config()
const fs = require("fs")
const { network } = require("hardhat")

module.exports = async ({ getNamedAccounts, deployments }) => {
    if (process.env.UPDATE_FRONT_END) {
        console.log("Writing to front end...")
        await updateContractAddresses()
        await updateAbi()
        console.log("Front end written!")
    }
}

async function updateAbi() {
    // const NFTBattleArena = await ethers.getContract("NFTBattleArena")
    // const { deployer } = await getNamedAccounts()
    // const signer = await ethers.getSigner(deployer)
    const _NFTBattleArena = await deployments.get("NFTBattleArena")
    // const NFTBattleArenaAddress = NFTBattleArena.address
    const NFTBattleArenaInstance = await ethers.getContractAt("NFTBattleArena", _NFTBattleArena.address)
    
    fs.writeFileSync(
        `${frontEndAbiLocation}NFTBattleArena.json`,
        NFTBattleArenaInstance.interface.formatJson()
    )

    const _WarriorNft = await deployments.get("WarriorNft")
    // const WarriorNftAddress = WarriorNft.address
    const WarriorNftInstance = await ethers.getContractAt(
        "WarriorNft",
        _WarriorNft.address
    )
    fs.writeFileSync(
        `${frontEndAbiLocation}WarriorNft.json`,
        WarriorNftInstance.interface.formatJson()
    )
}

async function updateContractAddresses() {
    const chainId = network.config.chainId.toString()
    // const NFTBattleArena = await ethers.getContract("NFTBattleArena")
    // const { deployer } = await getNamedAccounts()
    // const signer = await ethers.getSigner(deployer)
    const _NFTBattleArena = await deployments.get("NFTBattleArena")
    // const NFTBattleArenaAddress = NFTBattleArena.address
    const NFTBattleArenaInstance = await ethers.getContractAt("NFTBattleArena", _NFTBattleArena.address)
    
    const contractAddresses = JSON.parse(fs.readFileSync(frontEndContractsFile, "utf8"))
    if (chainId in contractAddresses) {
        if (!contractAddresses[chainId]["NFTBattleArena"].includes(_NFTBattleArena.address)) {
            contractAddresses[chainId]["NFTBattleArena"].push(_NFTBattleArena.address)
        }
    } else {
        contractAddresses[chainId] = { NFTBattleArena: [_NFTBattleArena.address] }
    }
    fs.writeFileSync(frontEndContractsFile, JSON.stringify(contractAddresses))
}
module.exports.tags = ["all", "frontend"]
