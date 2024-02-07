const { network } = require("hardhat")
const { developmentChains, VERIFICATION_BLOCK_CONFIRMATIONS } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")
const { storeImages, storeTokenUriMetadata } = require("../utils/uploadToPinata")
const fs = require("fs")
const path = require("path")


const MINT_FEE = ethers.parseEther("0.001")
const MAX_SUPPLY = 9999
let BasicNft, BasicNftAddress, BasicNftInstance

async function InitializeContract() {
    const { deployer } = await getNamedAccounts()
    const signer = await ethers.getSigner(deployer)
    BasicNft = await deployments.get("DragonNft")
    BasicNftAddress = BasicNft.address
    BasicNftInstance = await ethers.getContractAt(
        "DragonNft",
        BasicNftAddress,
        signer,
    )
    console.log(`initializing...`)
    const initializeTx = await BasicNftInstance._initializeContract(MAX_SUPPLY, MINT_FEE)
    await initializeTx.wait(1)
    console.log(initializeTx)
    if (network.config.chainId == 31337) {
        await moveBlocks(2, (sleepAmount = 1000))
    }
}

InitializeContract()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
