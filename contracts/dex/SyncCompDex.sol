// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../demo/DemoTxRecorder.sol";

/**
 * @title SyncCompDex
 * @dev A simplified DEX for demonstrating synchronous composability
 */
contract SyncCompDex is Ownable {
    IERC20 public cheeseToken;
    IERC20 public slothToken;
    address public l1Dex;
    DemoTxRecorder public txRecorder;

    event SwapExecuted(address indexed user, uint256 amountIn, uint256 amountOut);

    constructor(
        address _cheeseToken,
        address _slothToken,
        address _l1Dex,
        address _txRecorder
    ) Ownable(msg.sender) {
        cheeseToken = IERC20(_cheeseToken);
        slothToken = IERC20(_slothToken);
        l1Dex = _l1Dex;
        txRecorder = DemoTxRecorder(_txRecorder);
    }

    /**
     * @dev Execute a swap using synchronous composability with L1
     * This function simulates what would happen in a true synchronous composability environment
     * with Gwyneth, where the L2 transaction would access L1 liquidity in a single atomic transaction
     */
    function swapWithSyncComposability(uint256 amountIn) external returns (uint256 amountOut) {
        // Step 1: Transfer tokens from the user to this contract
        cheeseToken.transferFrom(msg.sender, address(this), amountIn);

        // Step 2: In a real implementation, these tokens would be burned on L2
        // and the equivalent amount would be released on L1

        // Step 3: Simulate the swap on L1
        // In a real implementation, this would be a cross-chain call to the L1 DEX
        (uint256 recordedAmountIn, uint256 recordedAmountOut, ) = txRecorder.getTransactionLog();
        amountOut = recordedAmountOut;

        // Step 4: In a real implementation, the output tokens would be locked on L1
        // and the equivalent amount would be minted on L2

        // Step 5: Transfer the output tokens to the user
        slothToken.transfer(msg.sender, amountOut);

        // Record the transaction for the demo
        txRecorder.recordTransaction(amountIn, amountOut);

        // Emit an event to mark the completion of the synchronous swap
        emit SwapExecuted(msg.sender, amountIn, amountOut);

        return amountOut;
    }
}