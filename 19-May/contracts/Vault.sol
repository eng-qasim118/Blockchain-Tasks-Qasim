// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is Ownable {
    mapping(address => uint256) private s_balances;
    mapping(address => uint256) private s_lastWithdrawTimestamp;
    uint256 public constant MIN_DEPOSIT = 1 ether;
    uint256 public withdrawLimit = 5 ether;
    uint256 public withdrawalDelay = 1 days;

    error Vault__InvalidDeposit();
    error Vault__NotEnoughBalance();
    error Vault__WithdrawalTooSoon();
    error Vault__ExceedsDailyLimit();
    error Vault__WithdrawFailed();
    error Vault__InvalidRecipient();

    event Vault__Deposited(address indexed user, uint256 amount);
    event Vault__Withdrawn(address indexed user, uint256 amount);
    event Vault__Transferred(
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event Vault__DailyLimitUpdated(uint256 newLimit);
    event Vault__WithdrawalDelayUpdated(uint256 newDelay);

    constructor() Ownable(msg.sender) {} // test done

    function deposit() external payable {
        // deposite function test done
        if (msg.value < MIN_DEPOSIT) revert Vault__InvalidDeposit(); // validation test done
        s_balances[msg.sender] += msg.value;
        emit Vault__Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        //withdarw function test done
        if (s_balances[msg.sender] < amount) revert Vault__NotEnoughBalance(); //test done
        if (
            block.timestamp <
            s_lastWithdrawTimestamp[msg.sender] + withdrawalDelay
        ) {
            revert Vault__WithdrawalTooSoon(); //validation test done
        }
        if (amount > withdrawLimit) revert Vault__ExceedsDailyLimit(); //validation test done

        s_balances[msg.sender] -= amount;
        s_lastWithdrawTimestamp[msg.sender] = block.timestamp;

        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) revert Vault__WithdrawFailed();

        emit Vault__Withdrawn(msg.sender, amount);
    }

    function transfer(address to, uint256 amount) external {
        // transfer test done
        if (to == address(0) || to == msg.sender)
            revert Vault__InvalidRecipient(); // validation test done
        if (s_balances[msg.sender] < amount) revert Vault__NotEnoughBalance(); //validation test done

        s_balances[msg.sender] -= amount;
        s_balances[to] += amount;

        emit Vault__Transferred(msg.sender, to, amount);
    }

    function setDailyLimit(uint256 newLimit) external onlyOwner {
        withdrawLimit = newLimit; //test done
        emit Vault__DailyLimitUpdated(newLimit); //test done
    }

    function setWithdrawalDelay(uint256 newDelay) external onlyOwner {
        withdrawalDelay = newDelay; //test done
        emit Vault__WithdrawalDelayUpdated(newDelay); //test done
    }

    // View functions
    function getBalance(address user) external view returns (uint256) {
        return s_balances[user];
    }

    function nextWithdrawTime(address user) external view returns (uint256) {
        return s_lastWithdrawTimestamp[user] + withdrawalDelay; //test done
    }
}
