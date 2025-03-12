// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SlothToken
 * @dev ERC20 token that represents Sloth - deployed on L1
 */
contract SlothToken is ERC20, Ownable {
    constructor(address initialOwner) ERC20("Sloth", "SLOTH") Ownable(initialOwner) {
        _mint(initialOwner, 1000000 * 10 ** decimals());
    }

    /**
     * @dev Mint new Sloth tokens (only owner)
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}