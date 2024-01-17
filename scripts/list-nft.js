const { ethers, network, getNamedAccounts, deployments} = require("hardhat")
const { moveBlocks } = require("../utils/move-blocks")

const TOKEN_ID = 1

let NFTBattleArena, NFTBattleArenaAddress, NFTBattleArenaInstance
let WarriorNft, WarriorNftAddress, WarriorNftInstance

async function listnft() {
    const { deployer } = await getNamedAccounts()
    const signer = await ethers.getSigner(deployer)
    WarriorNft = await deployments.get("WarriorNft")
    WarriorNftAddress = WarriorNft.address
    WarriorNftInstance = await ethers.getContractAt(
        "WarriorNft",
        WarriorNftAddress,
        signer,
    )
    NFTBattleArena = await deployments.get("NFTBattleArena")
    NFTBattleArenaAddress = NFTBattleArena.address
    NFTBattleArenaInstance = await ethers.getContractAt(
        "NFTBattleArena",
        NFTBattleArenaAddress,
        signer,
    )
    console.log("Approving NFT...")
    const approvalTx = await WarriorNftInstance.approve(NFTBattleArenaAddress, TOKEN_ID)
    await approvalTx.wait(1)
    console.log(`Listing an NFT with token id: ${TOKEN_ID}`)
    const airdropTx = await NFTBattleArenaInstance.listNFTForBattle(TOKEN_ID)
    await airdropTx.wait(1)
    // console.log(airdropTx)
    if (network.config.chainId == 31337) {
        // Moralis has a hard time if you move more than 1 block!
        await moveBlocks(2, (sleepAmount = 1000))
    }
}

listnft()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
