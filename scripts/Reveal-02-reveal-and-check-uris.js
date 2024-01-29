const { ethers, network, getNamedAccounts, deployments} = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")

const TOKEN_ID = 0
let BasicNft, BasicNftAddress, BasicNftInstance

async function revealAndCheckUris() {
    const { deployer } = await getNamedAccounts()
    const signer = await ethers.getSigner(deployer)
    BasicNft = await deployments.get("DragonNft")
    BasicNftAddress = BasicNft.address
    BasicNftInstance = await ethers.getContractAt(
        "DragonNft",
        BasicNftAddress,
        signer,
    )
    console.log(`UNrevealed TokenURI of the NFT #${TOKEN_ID} is ...`)
    const uriTx = await BasicNftInstance.tokenURI(TOKEN_ID)
    console.log(uriTx)
    console.log(`Revealing`)
    const revealTx = await BasicNftInstance.reveal()
    await revealTx.wait(1)
    console.log(`REVEALD TokenURI of the NFT #${TOKEN_ID} is ...`)
    const RevealedTx = await BasicNftInstance.tokenURI(TOKEN_ID)
    console.log(RevealedTx)
    
    if (network.config.chainId == 31337) {
        // Moralis has a hard time if you move more than 1 block!
        await moveBlocks(2, (sleepAmount = 1000))
    }
}

revealAndCheckUris()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
