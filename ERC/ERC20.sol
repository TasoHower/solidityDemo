// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract ERC20Basic {
    uint256 public _totalSupply;

    function totalSupply() public view virtual returns (uint);

    function balanceOf(address who) public view virtual returns (uint);

    function transfer(address to, uint value) public virtual;

    event Transfer(address indexed from, address indexed to, uint value);
}

abstract contract ERC20 is ERC20Basic {
    function allowance(
        address owner,
        address spender
    ) public view virtual returns (uint);

    function transferFrom(address from, address to, uint value) public virtual;

    function approve(address spender, uint value) public virtual;

    event Approval(address indexed owner, address indexed spender, uint value);
}
