const { ethers, network, getNamedAccounts, deployments} = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")

const PRICE = ethers.parseEther("0.01")
let WarriorNft, WarriorNftAddress, WarriorNftInstance

async function mintAndList() {
    const { deployer } = await getNamedAccounts()
    const signer = await ethers.getSigner(deployer)
    WarriorNft = await deployments.get("WarriorNft")
    WarriorNftAddress = WarriorNft.address
    WarriorNftInstance = await ethers.getContractAt(
        "WarriorNft",
        WarriorNftAddress,
        signer,
    )
    console.log("Minting NFT...")
    const mintTx = await WarriorNftInstance.mintNft({value: PRICE})
    const mintTxReceipt = await mintTx.wait(1)
    console.log(
        `Minted tokenId ${mintTxReceipt.logs[0].args.tokenId.toString()} from contract: ${
            WarriorNftAddress
        }`
    )
    if (network.config.chainId == 31337) {
        // Moralis has a hard time if you move more than 1 block!
        await moveBlocks(2, (sleepAmount = 1000))
    }
}

mintAndList()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
