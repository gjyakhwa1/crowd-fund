//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommissionStore {
    uint public totalCommissionReceived;
    uint public commissionWithdrawn;
    address public admin;
    constructor() {
        admin = msg.sender;
    }

    function updateCommissionAmount(uint _amount) external {
        totalCommissionReceived += _amount;
    }
    function withdrawCommission(address _admin) external payable {
        require(
            admin == _admin,
            "You are not system admin to withdraw commission"
        );
        uint commissionToWithdraw = totalCommissionReceived -
            commissionWithdrawn;
        payable(_admin).transfer(commissionToWithdraw);
        commissionWithdrawn += commissionToWithdraw;
    }
}