//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CommissionStore {
    uint public totalCommissionReceived;
    address payable public admin;
    constructor() {
        admin = payable(msg.sender);
    }
    function receiveCommission() external payable {
        totalCommissionReceived += msg.value;
    }

    function withdrawCommission() external payable {
        require(
            admin == msg.sender,
            "You are not system admin to withdraw commission"
        );
        payable(admin).transfer(address(this).balance);
    }
}
