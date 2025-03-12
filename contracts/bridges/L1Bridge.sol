// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title L1Bridge
 * @dev Bridge contract on L1 to handle token transfers between L1 and L2s
 */
contract L1Bridge is Ownable {
    using SafeERC20 for IERC20;

    // Mapping from token address to whether it's supported
    mapping(address => bool) public supportedTokens;

    // Events
    event TokenLocked(address indexed token, address indexed from, uint256 amount, uint256 destinationChainId);
    event TokenReleased(address indexed token, address indexed to, uint256 amount, uint256 sourceChainId);
    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);

    /**
     * @dev Constructor
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @dev Add a token to the list of supported tokens
     * @param token The token to add
     */
    function addToken(address token) external onlyOwner {
        require(token != address(0), "Token address cannot be zero");
        require(!supportedTokens[token], "Token already supported");
        supportedTokens[token] = true;
        emit TokenAdded(token);
    }

    /**
     * @dev Remove a token from the list of supported tokens
     * @param token The token to remove
     */
    function removeToken(address token) external onlyOwner {
        require(supportedTokens[token], "Token not supported");
        supportedTokens[token] = false;
        emit TokenRemoved(token);
    }

    /**
     * @dev Lock tokens on L1 to be minted on L2
     * @param token The token to lock
     * @param amount The amount to lock
     * @param destinationChainId The destination L2 chain ID
     */
    function lockTokens(address token, uint256 amount, uint256 destinationChainId) external {
        require(supportedTokens[token], "Token not supported");
        require(amount > 0, "Amount must be greater than zero");

        // Transfer tokens from the user to the bridge
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Emit event for L2 to pick up
        emit TokenLocked(token, msg.sender, amount, destinationChainId);
    }

    /**
     * @dev Release tokens on L1 when they are burned on L2
     * This would normally be called by a relayer/validator, but for this demo
     * we'll assume it's part of the synchronous composability mechanism
     * @param token The token to release
     * @param to The recipient address
     * @param amount The amount to release
     * @param sourceChainId The source L2 chain ID
     */
    function releaseTokens(address token, address to, uint256 amount, uint256 sourceChainId) external {
        require(supportedTokens[token], "Token not supported");
        require(amount > 0, "Amount must be greater than zero");

        // In a real implementation, there would be verification of the L2 burn
        // But for this demo, we'll assume that verification is handled by the synchronous composability mechanism

        // Transfer tokens from the bridge to the recipient
        IERC20(token).safeTransfer(to, amount);

        emit TokenReleased(token, to, amount, sourceChainId);
    }
}