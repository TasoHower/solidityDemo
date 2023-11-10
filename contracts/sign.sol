// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import "../Utils/owner.sol";

/**
 * 注意：代码未经测试，请勿直接商用
 *
 * Code by: Tasohower(https://github.com/TasoHower)
 * 部署地址： https://goerli.etherscan.io/address/0x2e44930fa9d407e814dc774f5714c0db9097b26b#code（已开源）
 */
contract Sign is ownerable {
    constructor() {
        member[msg.sender] = true;
        memberJoinTime[msg.sender] = block.timestamp;
        memberLen += 1;
    }

    // 交易议案
    struct TransactionProposal {
        address creator; // 创建人
        uint256 created_at; // 创建时间
        address to; // 交易对象
        string callData; // 交易内容
        uint256 requireVotes; // 通过所需同意人数
        uint256 expire_at; // 最迟交易时间
        uint256 agreed; // 同意人数
        uint256 value; // 发送的 eth 数目
    }

    // 投票成员地址
    mapping(address => bool) member;
    mapping(address => uint256) memberJoinTime;
    uint256 memberLen;

    // 交易号 => 交易详情
    mapping(bytes32 => TransactionProposal) transferPool;
    mapping(bytes32 => mapping(address => bool)) transferVoted;

    // 成员变化事件
    event AddNewMember(address newMember);
    event RemoveMember(address who);

    event TransferAdded(
        bytes32 random,
        address member,
        uint256 lastTime,
        string callData,
        uint256 requireVotes
    );

    event TransferCanBeDone(bytes32 proposal);
    event transferIsDone(bytes32 proposal);

    modifier onlyMember() {
        require(member[msg.sender], "only member");
        _;
    }

    function _isMember(address who) internal view onlyMember returns (bool) {
        return member[who];
    }

    function addMember(address who) public onlyOwner {
        require(!_isMember(who));

        member[who] = true;
        memberJoinTime[who] = block.timestamp;
        memberLen += 1;

        emit AddNewMember(who);
    }

    function transferOwner(address who) public override onlyOwner {
        require(_isMember(who), "new owner must is member");
        _owner = who;

        emit ownerTransfed(msg.sender, who);
    }

    function removeMember(address who) public onlyOwner {
        delete member[who];
        emit RemoveMember(who);
    }

    function addNewTransfer(
        string memory _callData,
        uint256 lastTime,
        uint256 _requireVotes,
        address to
    ) public payable onlyMember {
        require(_requireVotes > memberLen/2);
        
        bytes32 random = keccak256(
            abi.encodePacked(msg.sender, _callData, block.timestamp)
        );

        TransactionProposal memory newTP;
        newTP.agreed = 1;
        newTP.callData = _callData;
        newTP.creator = msg.sender;
        newTP.created_at = block.timestamp;
        newTP.expire_at = lastTime;
        newTP.requireVotes = _requireVotes;
        newTP.value = msg.value;
        newTP.to = to;
        

        transferVoted[random][msg.sender] = true;

        transferPool[random] = newTP;

        emit TransferAdded(
            random,
            msg.sender,
            lastTime,
            _callData,
            _requireVotes
        );
    }

    function vote(bytes32 proposal) public onlyMember {
        // 必须是创建之前存在的 member
        require(
            memberJoinTime[msg.sender] < transferPool[proposal].created_at,
            "must useful member"
        );
        // 必须没有投过票
        require(!transferVoted[proposal][msg.sender], "must not voted");
        // 交易必须有效
        require(
            transferPool[proposal].expire_at > block.timestamp,
            "transfer must useful"
        );

        TransactionProposal memory tp = transferPool[proposal];
        tp.agreed += 1;

        transferPool[proposal] = tp;

        if (tp.agreed >= tp.requireVotes) {
            emit TransferCanBeDone(proposal);
        }
    }

    function doTransfer(bytes32 proposal) public onlyMember {
        // 交易必须有效
        require(transferPool[proposal].expire_at > block.timestamp);
        // 交易必须足够票数
        require(
            transferPool[proposal].agreed >= transferPool[proposal].requireVotes
        );

        TransactionProposal memory tp = transferPool[proposal];

        (bool successed, ) = address(tp.to).call{value: tp.value}(
            abi.encode(tp.callData)
        );

        if (successed) {
            delete transferPool[proposal];
            emit transferIsDone(proposal);
        }
    }
}
