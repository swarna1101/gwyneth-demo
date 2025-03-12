// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../bridges/L2Bridge.sol";

/**
 * @title L2Dex
 * @dev A DEX on L2 that uses synchronous composability to access liquidity on L1
 * This is the core contract that demonstrates synchronous composability
 */
contract L2Dex is Ownable {
    // The L2 bridge contract
    L2Bridge public l2Bridge;

    // The L1 chain ID
    uint256 public constant L1_CHAIN_ID = 160010;

    // L1 contract addresses
    address public l1BridgeAddress;
    address public l1DexAddress;

    // Exchange rate variables (for simulation)
    uint256 public constant RATE_PRECISION = 10000;
    uint256 public cheeseToSlothRate = 5000; // 0.5 SLOTH per CHEESE (50%)

    // Mapping from L2 token address to whether it's supported
    mapping(address => bool) public supportedTokens;

    // Events
    event SwapExecuted(address indexed user, address indexed fromToken, address indexed toToken, uint256 amountIn, uint256 amountOut);
    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);

    /**
     * @dev Constructor
     * @param _l2Bridge The L2 bridge contract address
     * @param _l1BridgeAddress The L1 bridge contract address
     * @param _l1DexAddress The L1 DEX contract address
     */
    constructor(
        address _l2Bridge,
        address _l1BridgeAddress,
        address _l1DexAddress,
        address initialOwner
    ) Ownable(initialOwner) {
        require(_l2Bridge != address(0), "L2 bridge address cannot be zero");
        require(_l1BridgeAddress != address(0), "L1 bridge address cannot be zero");
        require(_l1DexAddress != address(0), "L1 DEX address cannot be zero");

        l2Bridge = L2Bridge(_l2Bridge);
        l1BridgeAddress = _l1BridgeAddress;
        l1DexAddress = _l1DexAddress;
    }

    /**
     * @dev Add a token to the list of supported tokens
     * @param l2Token The L2 token to add
     */
    function addToken(address l2Token) external onlyOwner {
        require(l2Token != address(0), "Token address cannot be zero");
        require(!supportedTokens[l2Token], "Token already supported");
        require(l2Bridge.getL1Token(l2Token) != address(0), "Token not mapped in bridge");

        supportedTokens[l2Token] = true;
        emit TokenAdded(l2Token);
    }

    /**
     * @dev Remove a token from the list of supported tokens
     * @param l2Token The L2 token to remove
     */
    function removeToken(address l2Token) external onlyOwner {
        require(supportedTokens[l2Token], "Token not supported");

        supportedTokens[l2Token] = false;
        emit TokenRemoved(l2Token);
    }

    /**
     * @dev Swap tokens using synchronous composability with L1
     * This is the main function that demonstrates synchronous composability
     * @param fromToken The token to swap from (on L2)
     * @param toToken The token to swap to (on L2)
     * @param amountIn The amount to swap
     * @return amountOut The amount received
     */
    function swapTokens(address fromToken, address toToken, uint256 amountIn) external returns (uint256 amountOut) {
        require(supportedTokens[fromToken], "From token not supported");
        require(supportedTokens[toToken], "To token not supported");
        require(amountIn > 0, "Amount must be greater than zero");

        // Step 1: Get the corresponding L1 token addresses
        address l1FromToken = l2Bridge.getL1Token(fromToken);
        address l1ToToken = l2Bridge.getL1Token(toToken);

        // Step 2: Transfer the tokens from the user to this contract
        IERC20(fromToken).transferFrom(msg.sender, address(this), amountIn);

        // Step 3: Approve the L2 bridge to spend the tokens
        IERC20(fromToken).approve(address(l2Bridge), amountIn);

        // Step 4: Burn the tokens on L2 to release them on L1
        // In a real implementation with true synchronous composability,
        // this would trigger a cross-chain call to the L1 bridge
        l2Bridge.burnTokens(fromToken, amountIn);

        // Step 5: Swap the tokens on L1
        // This is where the synchronous composability magic happens!
        // In a real implementation, this would be an atomic cross-chain call
        // For this demo, we'll use comments to indicate the L1 operations

        // [ON L1]: Release tokens to the L1 DEX
        // l1Bridge.releaseTokens(l1FromToken, l1DexAddress, amountIn, l2Bridge.chainId());

        // [ON L1]: Swap tokens on L1 DEX
        // amountOut = l1Dex.swapTokens(l1FromToken, l1ToToken, amountIn);

        // [ON L1]: Lock the output tokens in the L1 bridge
        // l1Bridge.lockTokens(l1ToToken, amountOut, l2Bridge.chainId());

        // Step 6: Mint the output tokens on L2
        // In a real implementation, this would be triggered by the L1 lock event
        // For this demo, we'll simulate the output amount and mint directly

        // Simulate the swap result (in a real implementation, this would come from L1)
        if (l1FromToken == l1ToToken) {
            amountOut = amountIn; // Same token, no change
        } else if (isCheeseToSloth(l1FromToken, l1ToToken)) {
            // Cheese to Sloth
            amountOut = (amountIn * cheeseToSlothRate) / RATE_PRECISION;
        } else {
            // Sloth to Cheese
            amountOut = (amountIn * RATE_PRECISION) / cheeseToSlothRate;
        }

        // Mint the tokens to the user
        // In a real implementation, this would be done by the L2 bridge
        // But for this demo, we'll mint from owner's authority
        L2Token(toToken).mint(msg.sender, amountOut);

        emit SwapExecuted(msg.sender, fromToken, toToken, amountIn, amountOut);

        return amountOut;
    }

    /**
     * @dev Check if the swap is from Cheese to Sloth
     * @param fromToken The token to swap from
     * @param toToken The token to swap to
     * @return True if the swap is from Cheese to Sloth
     */
    function isCheeseToSloth(address fromToken, address toToken) internal pure returns (bool) {
        // In a real implementation, this would check the token symbols or addresses
        // For this demo, we'll assume any comparison logic here
        return uint160(fromToken) < uint160(toToken);
    }

    /**
     * @dev Get the current exchange rate
     * @return The exchange rate in RATE_PRECISION units
     */
    function getExchangeRate() external view returns (uint256) {
        return cheeseToSlothRate;
    }

    /**
     * @dev Update the exchange rate (only owner)
     * @param newRate The new exchange rate in RATE_PRECISION units
     */
    function updateExchangeRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "Rate must be greater than zero");
        cheeseToSlothRate = newRate;
    }

    /**
     * @dev Calculate the output amount for a swap
     * @param fromToken The token to swap from
     * @param toToken The token to swap to
     * @param amountIn The amount to swap
     * @return The output amount
     */
    function getSwapAmount(address fromToken, address toToken, uint256 amountIn) external view returns (uint256) {
        require(supportedTokens[fromToken], "From token not supported");
        require(supportedTokens[toToken], "To token not supported");

        address l1FromToken = l2Bridge.getL1Token(fromToken);
        address l1ToToken = l2Bridge.getL1Token(toToken);

        if (l1FromToken == l1ToToken) {
            return amountIn; // Same token, no change
        } else if (isCheeseToSloth(l1FromToken, l1ToToken)) {
            // Cheese to Sloth
            return (amountIn * cheeseToSlothRate) / RATE_PRECISION;
        } else {
            // Sloth to Cheese
            return (amountIn * RATE_PRECISION) / cheeseToSlothRate;
        }
    }
}