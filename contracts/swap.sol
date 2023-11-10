// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../ERC/ERC20.sol";
import "../Utils/owner.sol";

abstract contract ERC20Swap is ERC20Basic, ERC20, ownerable {
    // 代币对地址
    address token0;
    address token1;

    // 代币对数量
    uint256 reserve0;
    uint256 reserve1;

    // 地址对应的 LP
    mapping(address => uint256) private _LPMap;

    constructor(address _token0, address _tooken1) {
        _owner = msg.sender;
        token0 = _token0;
        token1 = _tooken1;
    }

    function addLP(uint256 amount0, uint256 amount1) public {
        // 首先将代币入池
        ERC20(token0).transferFrom(msg.sender, address(this), amount0);
        ERC20(token1).transferFrom(msg.sender, address(this), amount1);

        uint256 reserve0After = reserve0 + amount0;
        uint256 reserve1After = reserve1 + amount1;
    }

    function _reserve() internal view returns (uint256, uint256) {
        return (reserve0,reserve1);
    }

    function _mint(address to, uint256 amount) internal {
        _LPMap[to] += amount;
    }
}
