const { ethers, network, getNamedAccounts, deployments} = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")

const PRICE = ethers.parseEther("0.01")
const QUANTITY = [1]
const RECEPIENTS = ["0xdaaEd1F389a89da771e0516ce2d0da018A92913b"]
let WarriorNft, WarriorNftAddress, WarriorNftInstance

async function airdropNfts() {
    const { deployer } = await getNamedAccounts()
    const signer = await ethers.getSigner(deployer)
    WarriorNft = await deployments.get("WarriorNft")
    WarriorNftAddress = WarriorNft.address
    WarriorNftInstance = await ethers.getContractAt(
        "WarriorNft",
        WarriorNftAddress,
        signer,
    )
    console.log("Airdropping NFTs...")
    const airdropTx = await WarriorNftInstance.airdropToken(QUANTITY, RECEPIENTS)
    const airdropTxReceipt = await airdropTx.wait(1)
    console.log(
        `Airdroped NFTs from contract: ${
            WarriorNftAddress
        }`
    )
    if (network.config.chainId == 31337) {
        // Moralis has a hard time if you move more than 1 block!
        await moveBlocks(2, (sleepAmount = 1000))
    }
}

airdropNfts()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
