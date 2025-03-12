require("dotenv").config();
const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
    console.log("Deploying Gwyneth Synchronous Composability Demo...");

    // Get the deployer account
    const [deployer] = await ethers.getSigners();
    console.log(`Deployer: ${deployer.address}`);

    // Get chain IDs from environment
    const L1_CHAIN_ID = process.env.L1_CHAIN_ID || 160010;
    const L2A_CHAIN_ID = process.env.L2A_CHAIN_ID || 167010;
    const L2B_CHAIN_ID = process.env.L2B_CHAIN_ID || 167011;

    console.log(`Using chain IDs: L1=${L1_CHAIN_ID}, L2A=${L2A_CHAIN_ID}, L2B=${L2B_CHAIN_ID}`);

    // Store all contract addresses
    const addresses = {};

    // Deploy L1 contracts
    console.log("\n--- Deploying L1 Contracts ---");

    // Deploy tokens
    const CheeseToken = await ethers.getContractFactory("CheeseToken");
    const cheeseToken = await CheeseToken.deploy(deployer.address);
    await cheeseToken.deployed();
    console.log(`CheeseToken deployed to: ${cheeseToken.address}`);
    addresses.cheeseToken = cheeseToken.address;

    const SlothToken = await ethers.getContractFactory("SlothToken");
    const slothToken = await SlothToken.deploy(deployer.address);
    await slothToken.deployed();
    console.log(`SlothToken deployed to: ${slothToken.address}`);
    addresses.slothToken = slothToken.address;

    // Deploy L1 Bridge
    const L1Bridge = await ethers.getContractFactory("L1Bridge");
    const l1Bridge = await L1Bridge.deploy(deployer.address);
    await l1Bridge.deployed();
    console.log(`L1Bridge deployed to: ${l1Bridge.address}`);
    addresses.l1Bridge = l1Bridge.address;

    // Add tokens to L1 Bridge
    await l1Bridge.addToken(cheeseToken.address);
    await l1Bridge.addToken(slothToken.address);
    console.log("Added tokens to L1Bridge");

    // Deploy L1 DEX
    const L1Dex = await ethers.getContractFactory("L1Dex");
    const l1Dex = await L1Dex.deploy(cheeseToken.address, slothToken.address, deployer.address);
    await l1Dex.deployed();
    console.log(`L1Dex deployed to: ${l1Dex.address}`);
    addresses.l1Dex = l1Dex.address;

    // Deploy L2A contracts
    console.log("\n--- Deploying L2A Contracts ---");

    // Deploy L2A Bridge
    const L2Bridge = await ethers.getContractFactory("L2Bridge");
    const l2ABridge = await L2Bridge.deploy(L2A_CHAIN_ID, deployer.address);
    await l2ABridge.deployed();
    console.log(`L2ABridge deployed to: ${l2ABridge.address}`);
    addresses.l2ABridge = l2ABridge.address;

    // Deploy L2A tokens (map to L1 tokens)
    console.log("Deploying and mapping L2A tokens...");

    try {
        // Deploy L2A Cheese token
        const l2ACheeseDeployTx = await l2ABridge.deployAndMapToken(
            cheeseToken.address, "L2A Cheese", "L2ACHEESE"
        );
        const l2ACheeseTxReceipt = await l2ACheeseDeployTx.wait();

        // Find the TokenMapped event
        let l2ACheeseAddress;
        for (const event of l2ACheeseTxReceipt.events) {
            if (event.event === "TokenMapped") {
                l2ACheeseAddress = event.args.l2Token;
                break;
            }
        }

        if (!l2ACheeseAddress) {
            // If event not found, try to get it by filtering logs
            const filter = l2ABridge.filters.TokenMapped(cheeseToken.address);
            const events = await l2ABridge.queryFilter(filter);
            if (events.length > 0) {
                l2ACheeseAddress = events[events.length - 1].args.l2Token;
            } else {
                throw new Error("Could not find L2A Cheese token address");
            }
        }

        // Deploy L2A Sloth token
        const l2ASlothDeployTx = await l2ABridge.deployAndMapToken(
            slothToken.address, "L2A Sloth", "L2ASLOTH"
        );
        const l2ASlothTxReceipt = await l2ASlothDeployTx.wait();

        // Find the TokenMapped event
        let l2ASlothAddress;
        for (const event of l2ASlothTxReceipt.events) {
            if (event.event === "TokenMapped") {
                l2ASlothAddress = event.args.l2Token;
                break;
            }
        }

        if (!l2ASlothAddress) {
            // If event not found, try to get it by filtering logs
            const filter = l2ABridge.filters.TokenMapped(slothToken.address);
            const events = await l2ABridge.queryFilter(filter);
            if (events.length > 0) {
                l2ASlothAddress = events[events.length - 1].args.l2Token;
            } else {
                throw new Error("Could not find L2A Sloth token address");
            }
        }

        console.log(`L2A Cheese Token deployed to: ${l2ACheeseAddress}`);
        console.log(`L2A Sloth Token deployed to: ${l2ASlothAddress}`);

        addresses.l2ACheeseToken = l2ACheeseAddress;
        addresses.l2ASlothToken = l2ASlothAddress;

        // Deploy L2A DEX
        const L2Dex = await ethers.getContractFactory("L2Dex");
        const l2ADex = await L2Dex.deploy(
            l2ABridge.address,
            l1Bridge.address,
            l1Dex.address,
            deployer.address
        );
        await l2ADex.deployed();
        console.log(`L2ADex deployed to: ${l2ADex.address}`);
        addresses.l2ADex = l2ADex.address;

        // Add tokens to L2A DEX
        await l2ADex.addToken(l2ACheeseAddress);
        await l2ADex.addToken(l2ASlothAddress);
        console.log("Added tokens to L2ADex");

        // Deploy L2B contracts
        console.log("\n--- Deploying L2B Contracts ---");

        // Deploy L2B Bridge
        const l2BBridge = await L2Bridge.deploy(L2B_CHAIN_ID, deployer.address);
        await l2BBridge.deployed();
        console.log(`L2BBridge deployed to: ${l2BBridge.address}`);
        addresses.l2BBridge = l2BBridge.address;

        // Deploy L2B tokens (map to L1 tokens)
        console.log("Deploying and mapping L2B tokens...");

        // Deploy L2B Cheese token
        const l2BCheeseDeployTx = await l2BBridge.deployAndMapToken(
            cheeseToken.address, "L2B Cheese", "L2BCHEESE"
        );
        const l2BCheeseTxReceipt = await l2BCheeseDeployTx.wait();

        // Find the TokenMapped event
        let l2BCheeseAddress;
        for (const event of l2BCheeseTxReceipt.events) {
            if (event.event === "TokenMapped") {
                l2BCheeseAddress = event.args.l2Token;
                break;
            }
        }

        if (!l2BCheeseAddress) {
            // If event not found, try to get it by filtering logs
            const filter = l2BBridge.filters.TokenMapped(cheeseToken.address);
            const events = await l2BBridge.queryFilter(filter);
            if (events.length > 0) {
                l2BCheeseAddress = events[events.length - 1].args.l2Token;
            } else {
                throw new Error("Could not find L2B Cheese token address");
            }
        }

        // Deploy L2B Sloth token
        const l2BSlothDeployTx = await l2BBridge.deployAndMapToken(
            slothToken.address, "L2B Sloth", "L2BSLOTH"
        );
        const l2BSlothTxReceipt = await l2BSlothDeployTx.wait();

        // Find the TokenMapped event
        let l2BSlothAddress;
        for (const event of l2BSlothTxReceipt.events) {
            if (event.event === "TokenMapped") {
                l2BSlothAddress = event.args.l2Token;
                break;
            }
        }

        if (!l2BSlothAddress) {
            // If event not found, try to get it by filtering logs
            const filter = l2BBridge.filters.TokenMapped(slothToken.address);
            const events = await l2BBridge.queryFilter(filter);
            if (events.length > 0) {
                l2BSlothAddress = events[events.length - 1].args.l2Token;
            } else {
                throw new Error("Could not find L2B Sloth token address");
            }
        }

        console.log(`L2B Cheese Token deployed to: ${l2BCheeseAddress}`);
        console.log(`L2B Sloth Token deployed to: ${l2BSlothAddress}`);

        addresses.l2BCheeseToken = l2BCheeseAddress;
        addresses.l2BSlothToken = l2BSlothAddress;

        // Deploy L2B DEX
        const l2BDex = await L2Dex.deploy(
            l2BBridge.address,
            l1Bridge.address,
            l1Dex.address,
            deployer.address
        );
        await l2BDex.deployed();
        console.log(`L2BDex deployed to: ${l2BDex.address}`);
        addresses.l2BDex = l2BDex.address;

        // Add tokens to L2B DEX
        await l2BDex.addToken(l2BCheeseAddress);
        await l2BDex.addToken(l2BSlothAddress);
        console.log("Added tokens to L2BDex");

        // Deploy SyncCompDemo contract
        console.log("\n--- Deploying Demo Contract ---");
        const SyncCompDemo = await ethers.getContractFactory("SyncCompDemo");
        const syncCompDemo = await SyncCompDemo.deploy(deployer.address);
        await syncCompDemo.deployed();
        console.log(`SyncCompDemo deployed to: ${syncCompDemo.address}`);
        addresses.syncCompDemo = syncCompDemo.address;

        // Initialize the demo contract
        await syncCompDemo.initialize(
            cheeseToken.address,
            slothToken.address,
            l1Dex.address,
            l1Bridge.address,
            l2ABridge.address,
            l2ADex.address,
            l2ACheeseAddress,
            l2ASlothAddress,
            l2BBridge.address,
            l2BDex.address,
            l2BCheeseAddress,
            l2BSlothAddress
        );
        console.log("SyncCompDemo initialized");

        // Setup tokens and liquidity for the demo
        await syncCompDemo.setupTokensAndLiquidity();
        console.log("Tokens and liquidity set up for the demo");

        // Log all contract addresses
        console.log("\n--- Deployment Summary ---");
        console.log(`CheeseToken (L1): ${cheeseToken.address}`);
        console.log(`SlothToken (L1): ${slothToken.address}`);
        console.log(`L1Bridge: ${l1Bridge.address}`);
        console.log(`L1Dex: ${l1Dex.address}`);
        console.log(`L2ABridge: ${l2ABridge.address}`);
        console.log(`L2ADex: ${l2ADex.address}`);
        console.log(`L2A Cheese Token: ${l2ACheeseAddress}`);
        console.log(`L2A Sloth Token: ${l2ASlothAddress}`);
        console.log(`L2BBridge: ${l2BBridge.address}`);
        console.log(`L2BDex: ${l2BDex.address}`);
        console.log(`L2B Cheese Token: ${l2BCheeseAddress}`);
        console.log(`L2B Sloth Token: ${l2BSlothAddress}`);
        console.log(`SyncCompDemo: ${syncCompDemo.address}`);

        // Save addresses to file
        fs.writeFileSync(
            "deployment-addresses.json",
            JSON.stringify(addresses, null, 2)
        );
        console.log("Deployment addresses saved to deployment-addresses.json");

        console.log("\nDeployment complete!");
        console.log("To run the demo, execute: npx hardhat run scripts/run-demo.js --network <network>");

    } catch (error) {
        console.error("Error during deployment:", error);
        // Save partial addresses if available
        if (Object.keys(addresses).length > 0) {
            fs.writeFileSync(
                "partial-deployment-addresses.json",
                JSON.stringify(addresses, null, 2)
            );
            console.log("Partial deployment addresses saved to partial-deployment-addresses.json");
        }
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });