// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title L2Token
 * @dev Represents a wrapped token on L2 that corresponds to a token on L1
 */
contract L2Token is ERC20, Ownable {
    address public l2Bridge;

    constructor(
        string memory name,
        string memory symbol,
        address _l2Bridge,
        address initialOwner
    ) ERC20(name, symbol) Ownable(initialOwner) {
        l2Bridge = _l2Bridge;
    }

    /**
     * @dev Mint tokens on L2 (only callable by the L2Bridge)
     * @param to The recipient address
     * @param amount The amount to mint
     */
    function mint(address to, uint256 amount) external {
        require(msg.sender == l2Bridge, "Only bridge can mint");
        _mint(to, amount);
    }

    /**
     * @dev Burn tokens on L2 (only callable by the L2Bridge)
     * @param from The address to burn from
     * @param amount The amount to burn
     */
    function burn(address from, uint256 amount) external {
        require(msg.sender == l2Bridge, "Only bridge can burn");
        _burn(from, amount);
    }
}

/**
 * @title L2Bridge
 * @dev Bridge contract on L2 to handle token transfers between L1 and L2
 */
contract L2Bridge is Ownable {
    uint256 public chainId;

    // Mapping from L1 token address to L2 token address
    mapping(address => address) public l1ToL2Tokens;

    // Mapping from L2 token address to L1 token address
    mapping(address => address) public l2ToL1Tokens;

    // Events
    event TokenMinted(address indexed l1Token, address indexed l2Token, address indexed to, uint256 amount);
    event TokenBurned(address indexed l1Token, address indexed l2Token, address indexed from, uint256 amount);
    event TokenMapped(address indexed l1Token, address indexed l2Token);

    /**
     * @dev Constructor
     * @param _chainId The chain ID of this L2
     */
    constructor(uint256 _chainId, address initialOwner) Ownable(initialOwner) {
        chainId = _chainId;
    }

    /**
     * @dev Map an L1 token to a newly deployed L2 token
     * @param l1Token The L1 token address
     * @param name The name of the L2 token
     * @param symbol The symbol of the L2 token
     * @return l2Token The address of the newly deployed L2 token
     */
    function deployAndMapToken(address l1Token, string memory name, string memory symbol) external onlyOwner returns (address) {
        require(l1Token != address(0), "L1 token address cannot be zero");
        require(l1ToL2Tokens[l1Token] == address(0), "L1 token already mapped");

        // Deploy a new L2 token
        L2Token l2Token = new L2Token(name, symbol, address(this), owner());

        // Map the tokens
        l1ToL2Tokens[l1Token] = address(l2Token);
        l2ToL1Tokens[address(l2Token)] = l1Token;

        emit TokenMapped(l1Token, address(l2Token));

        return address(l2Token);
    }

    /**
     * @dev Mint tokens on L2 when they are locked on L1
     * This would normally be called by a relayer/validator, but for this demo
     * we'll assume it's part of the synchronous composability mechanism
     * @param l1Token The L1 token address
     * @param to The recipient address
     * @param amount The amount to mint
     */
    function mintTokens(address l1Token, address to, uint256 amount) external {
        address l2Token = l1ToL2Tokens[l1Token];
        require(l2Token != address(0), "L1 token not mapped");

        // In a real implementation, there would be verification of the L1 lock
        // But for this demo, we'll assume that verification is handled by the synchronous composability mechanism

        // Mint tokens to the recipient
        L2Token(l2Token).mint(to, amount);

        emit TokenMinted(l1Token, l2Token, to, amount);
    }

    /**
     * @dev Burn tokens on L2 to be released on L1
     * @param l2Token The L2 token address
     * @param amount The amount to burn
     */
    function burnTokens(address l2Token, uint256 amount) external {
        address l1Token = l2ToL1Tokens[l2Token];
        require(l1Token != address(0), "L2 token not mapped");

        // Burn tokens from the sender
        L2Token(l2Token).burn(msg.sender, amount);

        // Emit event for L1 to pick up
        emit TokenBurned(l1Token, l2Token, msg.sender, amount);
    }

    /**
     * @dev Get the L2 token address for a given L1 token
     * @param l1Token The L1 token address
     * @return The L2 token address
     */
    function getL2Token(address l1Token) external view returns (address) {
        return l1ToL2Tokens[l1Token];
    }

    /**
     * @dev Get the L1 token address for a given L2 token
     * @param l2Token The L2 token address
     * @return The L1 token address
     */
    function getL1Token(address l2Token) external view returns (address) {
        return l2ToL1Tokens[l2Token];
    }
}