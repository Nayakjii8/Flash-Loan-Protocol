// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IFlashLoanReceiver {
    function executeOperation(uint256 amount, address token, bytes calldata data) external returns (bool);
}

contract FlashLoanProtocol {
    address public owner;
    IERC20 public token;

    event FlashLoanExecuted(address borrower, uint256 amount);

    constructor(address _token) {
        owner = msg.sender;
        token = IERC20(_token);
    }

    // Core function 1: Initiate flash loan
    function flashLoan(uint256 amount, address borrower, bytes calldata data) external {
        require(amount > 0, "Amount must be > 0");
        uint256 balanceBefore = tokenBalance();

        // Send tokens to borrower
        require(token.transfer(borrower, amount), "Transfer failed");

        // Callback: borrower executes operation (e.g., arbitrage)
        require(IFlashLoanReceiver(borrower).executeOperation(amount, address(token), data), "Callback failed");

        // Check funds are returned
        uint256 balanceAfter = tokenBalance();
        require(balanceAfter >= balanceBefore, "Loan not repaid");

        emit FlashLoanExecuted(borrower, amount);
    }

    // Core function 2: Get token balance held by this contract
    function tokenBalance() public view returns (uint256) {
        return tokenBalanceOf(address(this));
    }

    // Helper to query token balance of any address
    function tokenBalanceOf(address addr) internal view returns (uint256) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSignature("balanceOf(address)", addr)
        );
        require(success, "balanceOf call failed");
        return abi.decode(data, (uint256));
    }
}
