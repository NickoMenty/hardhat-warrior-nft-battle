const { network } = require("hardhat")
const { developmentChains, VERIFICATION_BLOCK_CONFIRMATIONS } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")
const { storeImages, storeTokenUriMetadata } = require("../utils/uploadToPinata")
const fs = require("fs")
const path = require("path")

const metadataLocation = "./SetUp-01-whitelistWallets.json"
let BasicNft, BasicNftAddress, BasicNftInstance

async function whitelistUser() {
    let whitelistedWallets
    
    const { deployer } = await getNamedAccounts()
    const signer = await ethers.getSigner(deployer)
    BasicNft = await deployments.get("DragonNft")
    BasicNftAddress = BasicNft.address
    BasicNftInstance = await ethers.getContractAt(
        "DragonNft",
        BasicNftAddress,
        signer,
    )
    
    console.log(`setting whitelistedWallets...`)
    if (process.env.UPLOAD_TO_PINATA == "true") {
        whitelistedWallets = await handlewhitelistedWallets()
    }

    async function handlewhitelistedWallets() {
        const metadataJson = JSON.parse(fs.readFileSync(metadataLocation, "utf8"))
        let i = 0;  // For loop initializer
        while (i < 1)  // For loop condition (and the actual loop)
        {   
            const tokenUri = metadataJson[i]
            console.log(tokenUri)
            console.log(`whitelisting ${tokenUri.wallet}...`)
            const urisTx = await BasicNftInstance._initializeContractURIs(whitelistedWallets)
            await urisTx.wait(1)
            console.log(urisTx)
            if (network.config.chainId == 31337) {
                await moveBlocks(2, (sleepAmount = 1000))
            }
            i++
        }    
        console.log("wallets are whitelisted! They are:")
        }
}

whitelistUser()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
