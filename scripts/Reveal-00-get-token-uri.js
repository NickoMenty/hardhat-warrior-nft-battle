const { ethers, network, getNamedAccounts, deployments} = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")

const TOKEN_ID = 1
let BasicNft, BasicNftAddress, BasicNftInstance

async function getTokenUris() {
    const { deployer } = await getNamedAccounts()
    const signer = await ethers.getSigner(deployer)
    BasicNft = await deployments.get("DragonNft")
    BasicNftAddress = BasicNft.address
    BasicNftInstance = await ethers.getContractAt(
        "DragonNft",
        BasicNftAddress,
        signer,
    )
    console.log(`getting TokenURI of the NFT #${TOKEN_ID}...`)
    const uriTx = await BasicNftInstance.tokenURI(TOKEN_ID)
    console.log(uriTx)
    if (network.config.chainId == 31337) {
        await moveBlocks(2, (sleepAmount = 1000))
    }
}

getTokenUris()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
