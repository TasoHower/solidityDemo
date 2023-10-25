// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

library Checker {
    modifier notContract(address who){
        uint size;
        assembly {
            size := extcodesize(who)
        }

        require(size == 0,"only not contract");
        _;
    }
}