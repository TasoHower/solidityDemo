// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract ownerable {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    event ownerTransfed(address older, address newOwner);

    function transferOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
        emit ownerTransfed(msg.sender, newOwner);
    }
}
