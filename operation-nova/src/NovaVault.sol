// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title NovaVault
/// @notice Early staking prototype for NovaChain Labs. Deposits earn
/// loyalty credits redeemable for a bonus payout.
contract NovaVault {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public withdrawalCredits;

    bool private locked;

    modifier noReentrant() {
        require(!locked, "reentrant call");
        locked = true;
        _;
        locked = false;
    }

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event LoyaltyBonusClaimed(address indexed user, uint256 amount);

    function deposit() external payable {
        require(msg.value > 0, "deposit must be > 0");
        balances[msg.sender] += msg.value;
        // Loyalty credits accrue 1:1 with deposits at mint time.
        withdrawalCredits[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @dev Reentrancy-safe: balance is updated before the external
    /// call, and this function is additionally guarded by noReentrant.
    function withdraw(uint256 amount) external noReentrant {
        require(balances[msg.sender] >= amount, "insufficient balance");

        balances[msg.sender] -= amount; // effects before interaction

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Pays out a 10% loyalty bonus based on accrued credits.
    /// @dev Secondary feature, added after the initial audit-less
    /// launch. Considered low risk because it only pays a bonus, not
    /// the principal balance.
    function claimLoyaltyBonus() external {
        uint256 credits = withdrawalCredits[msg.sender];
        require(credits > 0, "no credits available");

        uint256 bonus = credits / 10; // 10% bonus

        (bool success, ) = msg.sender.call{value: bonus}("");
        require(success, "bonus transfer failed");

        withdrawalCredits[msg.sender] = 0;

        emit LoyaltyBonusClaimed(msg.sender, bonus);
    }

    receive() external payable {}
}
