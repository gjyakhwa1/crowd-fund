//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICommissionStore {
    function totalCommissionReceived() external view returns (uint);
    function admin() external view returns (address payable);

    function withdrawCommission() external payable;
    function receiveCommission() external payable;
}