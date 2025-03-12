// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../tokens/CheeseToken.sol";
import "../tokens/SlothToken.sol";
import "../bridges/L1Bridge.sol";
import "../bridges/L2Bridge.sol";
import "../dex/L1Dex.sol";
import "../dex/L2Dex.sol";

/**
 * @title SyncCompDemo
 * @dev Main contract for demonstrating synchronous composability across L1 and L2
 * This contract orchestrates the entire demo flow, showing the power of
 * synchronous composability between chains
 */
contract SyncCompDemo is Ownable {
    // Chain IDs
    uint256 public constant L1_CHAIN_ID = 160010;
    uint256 public constant L2A_CHAIN_ID = 167010;
    uint256 public constant L2B_CHAIN_ID = 167011;

    // L1 contracts
    CheeseToken public cheeseToken;
    SlothToken public slothToken;
    L1Dex public l1Dex;
    L1Bridge public l1Bridge;

    // L2A contracts
    L2Bridge public l2ABridge;
    L2Dex public l2ADex;
    address public l2ACheese;
    address public l2ASloth;

    // L2B contracts
    L2Bridge public l2BBridge;
    L2Dex public l2BDex;
    address public l2BCheese;
    address public l2BSloth;

    // Events
    event DemoInitialized(address l1Dex, address l2ADex, address l2BDex);
    event DemoStepCompleted(uint256 step, string description);

    /**
     * @dev Constructor
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @dev Initialize the demo by setting up all contract references
     * @param _cheeseToken The Cheese token contract on L1
     * @param _slothToken The Sloth token contract on L1
     * @param _l1Dex The DEX contract on L1
     * @param _l1Bridge The bridge contract on L1
     * @param _l2ABridge The bridge contract on L2A
     * @param _l2ADex The DEX contract on L2A
     * @param _l2ACheese The Cheese token contract on L2A
     * @param _l2ASloth The Sloth token contract on L2A
     * @param _l2BBridge The bridge contract on L2B
     * @param _l2BDex The DEX contract on L2B
     * @param _l2BCheese The Cheese token contract on L2B
     * @param _l2BSloth The Sloth token contract on L2B
     */
    function initialize(
        address _cheeseToken,
        address _slothToken,
        address _l1Dex,
        address _l1Bridge,
        address _l2ABridge,
        address _l2ADex,
        address _l2ACheese,
        address _l2ASloth,
        address _l2BBridge,
        address _l2BDex,
        address _l2BCheese,
        address _l2BSloth
    ) external onlyOwner {
        cheeseToken = CheeseToken(_cheeseToken);
        slothToken = SlothToken(_slothToken);
        l1Dex = L1Dex(_l1Dex);
        l1Bridge = L1Bridge(_l1Bridge);

        l2ABridge = L2Bridge(_l2ABridge);
        l2ADex = L2Dex(_l2ADex);
        l2ACheese = _l2ACheese;
        l2ASloth = _l2ASloth;

        l2BBridge = L2Bridge(_l2BBridge);
        l2BDex = L2Dex(_l2BDex);
        l2BCheese = _l2BCheese;
        l2BSloth = _l2BSloth;

        emit DemoInitialized(_l1Dex, _l2ADex, _l2BDex);
    }

    /**
     * @dev Setup the tokens and liquidity for the demo
     * This function will mint tokens and add liquidity to the L1 DEX
     */
    function setupTokensAndLiquidity() external onlyOwner {
        // Mint Cheese and Sloth tokens to this contract
        cheeseToken.mint(address(this), 100000 * 10**18);
        slothToken.mint(address(this), 50000 * 10**18);

        // Approve the L1 DEX to spend the tokens
        cheeseToken.approve(address(l1Dex), 50000 * 10**18);
        slothToken.approve(address(l1Dex), 25000 * 10**18);

        // Add liquidity to the L1 DEX
        l1Dex.addLiquidity(50000 * 10**18, 25000 * 10**18);

        emit DemoStepCompleted(1, "Tokens minted and liquidity added to L1 DEX");
    }

    /**
     * @dev Run the complete synchronous composability demo flow
     * @param user The user address to run the demo for
     */
    function runFullDemo(address user) external onlyOwner {
        require(user != address(0), "User address cannot be zero");

        // Step 1: Mint Cheese tokens to the user on L1
        cheeseToken.mint(user, 1000 * 10**18);
        emit DemoStepCompleted(2, "Minted 1000 Cheese tokens to user on L1");

        // Step 2: Transfer some Cheese tokens to L2A using the bridge
        // In a real implementation, the user would need to approve and call the bridge directly
        // For this demo, we'll simulate it by minting on L2 directly
        L2Token(l2ACheese).mint(user, 500 * 10**18);
        emit DemoStepCompleted(3, "Transferred 500 Cheese tokens to user on L2A");

        // Step 3: Setup L2A for the synchronous swap demo
        // The user can now use these tokens to do a swap on L2A, which will
        // utilize synchronous composability to access the liquidity on L1
        emit DemoStepCompleted(4, "User can now swap Cheese for Sloth on L2A using synchronous composability");

        // Note: The actual swap would be performed by the user by calling:
        // l2ADex.swapTokens(l2ACheese, l2ASloth, amount);
    }

    /**
     * @dev Demonstrate the synchronous composability path from L2A to L1 and back
     * This function traces the logical flow of what happens during a synchronous swap
     * @param amount The amount of tokens to swap (for demonstration purposes)
     */
    function traceSynchronousSwapPath(uint256 amount) external view returns (string memory) {
        require(amount > 0, "Amount must be greater than zero");

        // Calculate the expected output amount
        uint256 rate = l1Dex.cheeseToSlothRate();
        uint256 ratePrecision = l1Dex.RATE_PRECISION();
        uint256 expectedOutput = (amount * rate) / ratePrecision;

        // Return a description of the synchronous composability path
        return string(abi.encodePacked(
            "Synchronous Composability Path for swapping ",
            uint2str(amount / 10**18), " Cheese for Sloth:\n",
            "1. User calls swapTokens(Cheese, Sloth, ", uint2str(amount / 10**18), ") on L2A DEX\n",
            "2. L2A burns the Cheese tokens and notifies L1\n",
            "3. L1 Bridge releases Cheese tokens to the L1 DEX\n",
            "4. L1 DEX swaps Cheese for ", uint2str(expectedOutput / 10**18), " Sloth tokens\n",
            "5. L1 Bridge locks the Sloth tokens and notifies L2A\n",
            "6. L2A mints ", uint2str(expectedOutput / 10**18), " Sloth tokens to the user\n",
            "7. All of this happens in a single atomic transaction!"
        ));
    }

    /**
     * @dev Helper function to convert uint to string
     * @param _i The uint to convert
     * @return The string representation
     */
    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /**
    * @dev Get the balances of a user across all chains and tokens
     * @param user The user address to check
     * @return l1CheeseBalance The user's Cheese token balance on L1
     * @return l1SlothBalance The user's Sloth token balance on L1
     * @return l2ACheeseBalance The user's Cheese token balance on L2A
     * @return l2ASlothBalance The user's Sloth token balance on L2A
     * @return l2BCheeseBalance The user's Cheese token balance on L2B
     * @return l2BSlothBalance The user's Sloth token balance on L2B
     */
    function getUserBalances(address user) external view returns (
        uint256 l1CheeseBalance,
        uint256 l1SlothBalance,
        uint256 l2ACheeseBalance,
        uint256 l2ASlothBalance,
        uint256 l2BCheeseBalance,
        uint256 l2BSlothBalance
    ) {
        l1CheeseBalance = cheeseToken.balanceOf(user);
        l1SlothBalance = slothToken.balanceOf(user);

        l2ACheeseBalance = IERC20(l2ACheese).balanceOf(user);
        l2ASlothBalance = IERC20(l2ASloth).balanceOf(user);

        l2BCheeseBalance = IERC20(l2BCheese).balanceOf(user);
        l2BSlothBalance = IERC20(l2BSloth).balanceOf(user);
    }
}