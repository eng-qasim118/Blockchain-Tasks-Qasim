// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract Bank{
    mapping (address=>uint) public s_balance;

    error Bank__InvalidDeposite();
    error Bank__NotEnoughBalance();
    error Bank__WithdarwFailed();
    event Bank__Deposite(address indexed user,uint amount);
    event Bank__Withdraw(address indexed user,uint amount);
    

    function deposite() external  payable  {
        if(msg.value<1 ether){
            revert Bank__InvalidDeposite();
        }
        s_balance[msg.sender]+=msg.value;
        emit Bank__Deposite(msg.sender, msg.value);
    }

    function withdraw(uint _amount) external   {
        
        if(s_balance[msg.sender]<_amount){
            revert Bank__NotEnoughBalance();
        }
       
        (bool success , ) = msg.sender.call{value:_amount}("");
        if(!success){
            revert Bank__WithdarwFailed();
        }
        s_balance[msg.sender]-=_amount;
        emit Bank__Withdraw(msg.sender,_amount);
    }
}