// SPDX-License-Identifier: MIT 
pragma solidity 0.8.19;

abstract contract ERC20Basic {
    uint256 public _totalSupply;
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address who) virtual public view returns (uint);
    function transfer(address to, uint value) virtual public;
    event Transfer(address indexed from, address indexed to, uint value);
}

abstract contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) virtual public view returns (uint);
    function transferFrom(address from, address to, uint value) virtual public;
    function approve(address spender, uint value) virtual public;
    event Approval(address indexed owner, address indexed spender, uint value);
}