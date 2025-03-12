// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title L1Dex
 * @dev A simple DEX for the L1 that includes a liquidity pool for Cheese and Sloth tokens
 * This contract will be used to demonstrate synchronous composability from L2
 */
contract L1Dex is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public cheeseToken;
    IERC20 public slothToken;

    // Exchange rate variables
    uint256 public constant RATE_PRECISION = 10000;
    uint256 public cheeseToSlothRate = 5000; // 0.5 SLOTH per CHEESE (50%)

    // Events
    event LiquidityAdded(address indexed provider, uint256 cheeseAmount, uint256 slothAmount);
    event SwapExecuted(address indexed user, address indexed fromToken, address indexed toToken, uint256 amountIn, uint256 amountOut);
    event RateUpdated(uint256 newRate);

    /**
     * @dev Constructor sets token addresses and initial exchange rate
     * @param _cheeseToken Address of the Cheese token contract
     * @param _slothToken Address of the Sloth token contract
     */
    constructor(address _cheeseToken, address _slothToken, address initialOwner) Ownable(initialOwner) {
        require(_cheeseToken != address(0) && _slothToken != address(0), "Token addresses cannot be zero");
        cheeseToken = IERC20(_cheeseToken);
        slothToken = IERC20(_slothToken);
    }

    /**
     * @dev Add liquidity to the DEX
     * @param cheeseAmount Amount of Cheese tokens to add
     * @param slothAmount Amount of Sloth tokens to add
     */
    function addLiquidity(uint256 cheeseAmount, uint256 slothAmount) external {
        require(cheeseAmount > 0 && slothAmount > 0, "Amounts must be greater than zero");

        // Transfer tokens from the user to the DEX
        cheeseToken.safeTransferFrom(msg.sender, address(this), cheeseAmount);
        slothToken.safeTransferFrom(msg.sender, address(this), slothAmount);

        emit LiquidityAdded(msg.sender, cheeseAmount, slothAmount);
    }

    /**
     * @dev Swap Cheese tokens for Sloth tokens
     * @param cheeseAmount Amount of Cheese tokens to swap
     * @return slothAmount Amount of Sloth tokens received
     */
    function swapCheeseForSloth(uint256 cheeseAmount) external returns (uint256 slothAmount) {
        require(cheeseAmount > 0, "Amount must be greater than zero");

        // Calculate how many Sloth tokens to give based on the rate
        slothAmount = (cheeseAmount * cheeseToSlothRate) / RATE_PRECISION;

        // Check if the DEX has enough Sloth tokens
        require(slothToken.balanceOf(address(this)) >= slothAmount, "Insufficient Sloth liquidity");

        // Transfer Cheese tokens from the user to the DEX
        cheeseToken.safeTransferFrom(msg.sender, address(this), cheeseAmount);

        // Transfer Sloth tokens from the DEX to the user
        slothToken.safeTransfer(msg.sender, slothAmount);

        emit SwapExecuted(msg.sender, address(cheeseToken), address(slothToken), cheeseAmount, slothAmount);

        return slothAmount;
    }

    /**
     * @dev Swap Sloth tokens for Cheese tokens
     * @param slothAmount Amount of Sloth tokens to swap
     * @return cheeseAmount Amount of Cheese tokens received
     */
    function swapSlothForCheese(uint256 slothAmount) external returns (uint256 cheeseAmount) {
        require(slothAmount > 0, "Amount must be greater than zero");

        // Calculate how many Cheese tokens to give based on the inverse rate
        cheeseAmount = (slothAmount * RATE_PRECISION) / cheeseToSlothRate;

        // Check if the DEX has enough Cheese tokens
        require(cheeseToken.balanceOf(address(this)) >= cheeseAmount, "Insufficient Cheese liquidity");

        // Transfer Sloth tokens from the user to the DEX
        slothToken.safeTransferFrom(msg.sender, address(this), slothAmount);

        // Transfer Cheese tokens from the DEX to the user
        cheeseToken.safeTransfer(msg.sender, cheeseAmount);

        emit SwapExecuted(msg.sender, address(slothToken), address(cheeseToken), slothAmount, cheeseAmount);

        return cheeseAmount;
    }

    /**
     * @dev Update the exchange rate (only owner)
     * @param newRate New exchange rate (in RATE_PRECISION units)
     */
    function updateRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "Rate must be greater than zero");
        cheeseToSlothRate = newRate;
        emit RateUpdated(newRate);
    }

    /**
     * @dev Get the current liquidity in the DEX
     * @return cheeseBalance The current Cheese token balance
     * @return slothBalance The current Sloth token balance
     */
    function getLiquidity() external view returns (uint256 cheeseBalance, uint256 slothBalance) {
        cheeseBalance = cheeseToken.balanceOf(address(this));
        slothBalance = slothToken.balanceOf(address(this));
    }

    /**
     * @dev Calculate how many Sloth tokens would be received for a given amount of Cheese tokens
     * @param cheeseAmount Amount of Cheese tokens
     * @return slothAmount Amount of Sloth tokens
     */
    function getCheeseToSlothAmount(uint256 cheeseAmount) external view returns (uint256 slothAmount) {
        return (cheeseAmount * cheeseToSlothRate) / RATE_PRECISION;
    }

    /**
     * @dev Calculate how many Cheese tokens would be received for a given amount of Sloth tokens
     * @param slothAmount Amount of Sloth tokens
     * @return cheeseAmount Amount of Cheese tokens
     */
    function getSlothToCheeseAmount(uint256 slothAmount) external view returns (uint256 cheeseAmount) {
        return (slothAmount * RATE_PRECISION) / cheeseToSlothRate;
    }
}