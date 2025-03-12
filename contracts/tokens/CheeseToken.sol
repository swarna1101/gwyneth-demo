// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CheeseToken
 * @dev ERC20 token that represents Cheese - deployed on L1
 */
contract CheeseToken is ERC20, Ownable {
    constructor(address initialOwner) ERC20("Cheese", "CHEESE") Ownable(initialOwner) {
        _mint(initialOwner, 1000000 * 10 ** decimals());
    }

    /**
     * @dev Mint new Cheese tokens (only owner)
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Public function to allow anyone to get some Cheese (faucet functionality)
     * Limited to 100 tokens per request to prevent abuse
     */
    function getFreeTokens() external {
        _mint(msg.sender, 100 * 10 ** decimals());
    }
}