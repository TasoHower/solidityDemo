// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import "../Utils/owner.sol";
import "./sign.sol";
import "./signV2.sol";

contract factory is ownerable {
    function createSign() public returns(address){
        bytes32 salt = keccak256(abi.encodePacked(msg.sender,msg.sender));
        
        Sign sign = new Sign{salt:salt}();

        return address(sign);
    }

    function createSignV2(address[] calldata members) public returns(address){
        SignV2 sign = new SignV2(members);
        return address(sign);
    }
}