# Developer

Name : Qasim Ikram
Task Date : 5/12/2025

# Bank Smart Contract

This is a simple **Bank smart contract** written in Solidity. Users can deposit and withdraw ETH securely on the Ethereum blockchain.

---

## Description

- Users **must deposit a minimum of 1 ETH** to the contract.
- Users can **withdraw any amount**, as long as they have enough balance stored in the contract.
- The contract ensures:
  - Only valid deposits (≥ 1 ETH) are accepted.
  - Only users with sufficient balance can withdraw.
  - Proper error handling and event logging for deposit and withdraw actions.

---

## Features

- ✅ Minimum 1 ETH deposit requirement.
- ✅ Safe withdrawal using `.call`.
- ✅ Custom error messages for better gas optimization.
- ✅ Emits events for both deposit and withdrawal.

---

## Contract Overview

<details>

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract Bank {
    mapping(address => uint) public s_balance;

    error Bank__InvalidDeposite();
    error Bank__NotEnoughBalance();
    error Bank__WithdarwFailed();

    event Bank__Deposite(address indexed user, uint amount);
    event Bank__Withdraw(address indexed user, uint amount);

    function deposite() external payable {
        if (msg.value < 1 ether) {
            revert Bank__InvalidDeposite();
        }
        s_balance[msg.sender] += msg.value;
        emit Bank__Deposite(msg.sender, msg.value);
    }

    function withdraw(uint _amount) external {
        if (s_balance[msg.sender] < _amount) {
            revert Bank__NotEnoughBalance();
        }

        (bool success, ) = msg.sender.call{value: _amount}("");
        if (!success) {
            revert Bank__WithdarwFailed();
        }

        s_balance[msg.sender] -= _amount;
        emit Bank__Withdraw(msg.sender, _amount);
    }
}
```

</details>
