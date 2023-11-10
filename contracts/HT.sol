// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../ERC/ERC20.sol";
import "../lib/safeMath.sol";
import "../Utils/owner.sol";

contract HowerToken is ownerable, ERC20 {
    using SafeMath for uint256;

    // ERC-20
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint256 public decimals;

    mapping(address => uint256) _balance;
    mapping(address => mapping(address => uint256)) _approval;

    // events
    event Mint(address to, uint256 number);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = 6;
        _mint(msg.sender, _totalSupply);
    }

    /**
     * Token Utils
     * 一组 Token 相关的工具函数:
     * _mint: 增发
     * _transfer：交易
     * _beforeTransfer: 交易前检查
     */
    function _mint(address to, uint256 number) internal {
        _balance[to] = _balance[to].add(number);
        totalSupply = totalSupply.add(number);

        emit Mint(to, number);
    }

    function _transfer(address from, address to, uint256 value) internal {
        _balance[from] = _balance[from].sub(value);
        _balance[to] = _balance[to].add(value);

        emit Transfer(from, to, value);
    }

    function _beforeTransfer(address from, uint256 value) internal view {
        require(_balance[from] > value, "balance fo from not enough");
    }

    function _beforeApprovalTransfer(
        address owner,
        uint256 value
    ) internal view {
        require(_approval[owner][msg.sender] >= value);
    }

    function _afterApprovalTransfer(address owner, uint256 value) internal {
        _approval[owner][msg.sender] = _approval[owner][msg.sender].sub(value);
    }

    /**
     * ERC-20 function
     */
    function transfer(address to, uint256 value) public override {
        _beforeTransfer(msg.sender, value);

        _transfer(msg.sender, to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override {
        _beforeApprovalTransfer(from, value);

        _transfer(from, to, value);

        _afterApprovalTransfer(from, value);
    }

    function balanceOf(address who) public view override returns (uint256) {
        return _balance[who];
    }

    function approve(address spender, uint value) public override {
        _approval[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _approval[owner][spender];
    }
}
