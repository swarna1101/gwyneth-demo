// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DemoTxRecorder
 * @dev A simple contract to record transaction details for the sync composability demo
 */
contract DemoTxRecorder is Ownable {
    struct TxLog {
        uint256 amountIn;
        uint256 amountOut;
        uint256 timestamp;
    }

    TxLog public lastTransaction;

    event TransactionRecorded(uint256 amountIn, uint256 amountOut, uint256 timestamp);

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Record a transaction for the demo
     */
    function recordTransaction(uint256 amountIn, uint256 amountOut) external {
        lastTransaction = TxLog({
            amountIn: amountIn,
            amountOut: amountOut,
            timestamp: block.timestamp
        });

        emit TransactionRecorded(amountIn, amountOut, block.timestamp);
    }

    /**
     * @dev Set L1 swap details for the demo
     */
    function setL1SwapDetails(uint256 amountIn, uint256 amountOut) external onlyOwner {
        lastTransaction = TxLog({
            amountIn: amountIn,
            amountOut: amountOut,
            timestamp: block.timestamp
        });
    }

    /**
     * @dev Get the transaction log
     * @return amountIn The input amount
     * @return amountOut The output amount
     * @return timestamp The timestamp
     */
    function getTransactionLog() external view returns (uint256 amountIn, uint256 amountOut, uint256 timestamp) {
        return (lastTransaction.amountIn, lastTransaction.amountOut, lastTransaction.timestamp);
    }
}