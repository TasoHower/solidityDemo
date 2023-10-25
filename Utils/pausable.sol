// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./owner.sol";

contract Pausable is ownerable {
    bool _pause;

    constructor() {
        _pause = false;
    }

    modifier onlyPaused() {
        require(_pause, "only paused");
        _;
    }

    modifier onlyNotpaused() {
        require(!_pause, "only not pause");
        _;
    }

    event Pause();
    event Unpause();

    function pause() public onlyNotpaused onlyOwner {
        _pause = true;
    }

    function unpause() public onlyPaused onlyOwner {
        _pause = false;
    }
}
