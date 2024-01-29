const { network } = require("hardhat")
const { developmentChains, VERIFICATION_BLOCK_CONFIRMATIONS } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")
const { storeImages, storeTokenUriMetadata } = require("../utils/uploadToPinata")
const fs = require("fs")
const path = require("path")

const MINT_FEE = ethers.parseEther("0.01")
const MAX_SUPPLY = 10
const metadataLocation = "./dragonsNfts.json"

module.exports = async ({ getNamedAccounts, deployments }) => {
    
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const waitBlockConfirmations = developmentChains.includes(network.name)
        ? 1
        : VERIFICATION_BLOCK_CONFIRMATIONS

    log("----------------------------------------------------")
    let tokenUris
    if (process.env.UPLOAD_TO_PINATA == "true") {
        tokenUris = await handleTokenUris()
    }
    // await storeTokenUriMetadata(metadata)
    const args = [MINT_FEE, tokenUris, MAX_SUPPLY]
    const DragonNft = await deploy("DragonNft", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: waitBlockConfirmations,
    })

    // Verify the deployment
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(DragonNft.address, args)
    }
    log("----------------------------------------------------")

    async function handleTokenUris() {
        // Check out https://github.com/PatrickAlphaC/nft-mix for a pythonic version of uploading
        // to the raw IPFS-daemon from https://docs.ipfs.io/how-to/command-line-quick-start/
        // You could also look at pinata https://www.pinata.cloud/
        const metadataJson = JSON.parse(fs.readFileSync(metadataLocation, "utf8"))
        tokenUris = []
        let i = 0;  // For loop initializer
        while (i < 10)  // For loop condition (and the actual loop)
        {   
            const tokenUri = metadataJson[i]
            console.log(`Uploading ${tokenUri.name}...`)
            const metadataUploadResponse = await storeTokenUriMetadata(tokenUri)
            tokenUris.push(`ipfs://${metadataUploadResponse.IpfsHash}`)
            i++
        }    
        console.log("Token URIs uploaded! They are:")
        console.log(tokenUris)
        return tokenUris
    }
        
}




module.exports.tags = ["all", "DragonNft","UsingJSON"]
