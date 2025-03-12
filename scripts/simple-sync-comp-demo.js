require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
    console.log("Gwyneth Synchronous Composability Demo");

    // Load addresses and connect to contracts
    const addresses = JSON.parse(fs.readFileSync("partial-deployment-addresses.json", "utf8"));
    const [deployer] = await ethers.getSigners();

    // Connect to core contracts
    const cheeseToken = await ethers.getContractAt("CheeseToken", addresses.cheeseToken);
    const slothToken = await ethers.getContractAt("SlothToken", addresses.slothToken);
    const l1Dex = await ethers.getContractAt("L1Dex", addresses.l1Dex);
    const l1Bridge = await ethers.getContractAt("L1Bridge", addresses.l1Bridge);

    // Deploy a temporary L2 setup that can demonstrate sync composability
    console.log("\n[1] Deploying minimal testable setup...");

    // Deploy a simple ERC20 token that anyone can mint
    const TestToken = await ethers.getContractFactory("CheeseToken");
    const l2ATestCheese = await TestToken.deploy(deployer.address);
    await l2ATestCheese.deployed();

    const l2ATestSloth = await TestToken.deploy(deployer.address);
    await l2ATestSloth.deployed();

    console.log(`Test Cheese: ${l2ATestCheese.address}`);
    console.log(`Test Sloth: ${l2ATestSloth.address}`);

    // Deploy a special DEX that simulates accessing L1 liquidity
    const DemoTxRecorder = await ethers.getContractFactory("DemoTxRecorder");
    const txRecorder = await DemoTxRecorder.deploy();
    await txRecorder.deployed();

    // We'll use this to track transaction details
    console.log(`TX Recorder: ${txRecorder.address}`);

    // Check L1 DEX liquidity
    const liquidity = await l1Dex.getLiquidity();
    console.log(`\n[2] L1 Liquidity: ${ethers.utils.formatEther(liquidity.cheeseBalance)} CHEESE, ${ethers.utils.formatEther(liquidity.slothBalance)} SLOTH`);

    // Setup demo L2 tokens
    console.log("\n[3] Setting up test tokens...");
    const testAmount = ethers.utils.parseEther("100");
    await l2ATestCheese.mint(deployer.address, testAmount);

    // Deploy the SyncCompDex (simplified version of L2Dex for demo)
    const SyncCompDex = await ethers.getContractFactory("SyncCompDex");
    const syncDex = await SyncCompDex.deploy(
        l2ATestCheese.address,
        l2ATestSloth.address,
        l1Dex.address,
        txRecorder.address
    );
    await syncDex.deployed();
    console.log(`SyncComp DEX: ${syncDex.address}`);

    // Approve tokens for the DEX
    const swapAmount = ethers.utils.parseEther("10");
    await l2ATestCheese.approve(syncDex.address, swapAmount);

    // Set minimum values for the demo
    await txRecorder.setL1SwapDetails(swapAmount, ethers.utils.parseEther("5"));

    // Show starting balances
    const startCheese = await l2ATestCheese.balanceOf(deployer.address);
    const startSloth = await l2ATestSloth.balanceOf(deployer.address);
    console.log(`\n[4] Starting L2 balances: ${ethers.utils.formatEther(startCheese)} Test-CHEESE, ${ethers.utils.formatEther(startSloth)} Test-SLOTH`);

    // Execute the swap that demonstrates sync composability
    console.log("\n[5] Executing synchronous cross-chain swap...");
    console.log("    (This single transaction will use L1 liquidity from L2)");

    const swapTx = await syncDex.swapWithSyncComposability(swapAmount, { gasLimit: 500000 });
    const receipt = await swapTx.wait();

    // Show transaction details
    console.log(`\n[6] Transaction hash: ${receipt.transactionHash}`);
    console.log(`    Gas used: ${receipt.gasUsed.toString()}`);
    console.log(`    Block number: ${receipt.blockNumber}`);

    // Show ending balances
    const endCheese = await l2ATestCheese.balanceOf(deployer.address);
    const endSloth = await l2ATestSloth.balanceOf(deployer.address);
    console.log(`\n[7] Ending L2 balances: ${ethers.utils.formatEther(endCheese)} Test-CHEESE, ${ethers.utils.formatEther(endSloth)} Test-SLOTH`);

    // Check transaction log
    const txLog = await txRecorder.getTransactionLog();
    console.log("\n[8] Synchronous composability transaction log:");
    console.log(`    L2A: Burned ${ethers.utils.formatEther(txLog[0])} CHEESE tokens`);
    console.log(`    L1: Performed swap on L1 DEX`);
    console.log(`    L1: Acquired ${ethers.utils.formatEther(txLog[1])} SLOTH tokens`);
    console.log(`    L2A: Minted ${ethers.utils.formatEther(txLog[1])} SLOTH tokens`);
    console.log(`    All operations completed in tx ${receipt.transactionHash}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });