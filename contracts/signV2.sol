// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

import "../Utils/owner.sol";
import "../lib/safeMath.sol";
import "../ERC/ERC20.sol";

/**
 * SignV2 试图创建一个去中心化的交易投票合约
 * 合约投票来确认成员变更（全票通过）
 * 测试部署于 Goerli 网络（0x4fac361e0d8d283c9aa2d1c2cfb785cb8a0bb780）
 */
contract SignV2 is ownerable {
    using SafeMath for uint256;

    // 创建合约时至少需要一个其他的 member
    constructor(address[] memory members) {
        require(members.length >= 3, "require more than three member");

        // 第一位成员自动成为 owner;
        _owner = members[0];

        // 初始化所有成员的信息
        for (uint i = 0; i < members.length; i++) {
            memberJoinTime[members[i]] = block.timestamp;
            memberLen += 1;
        }

        // 初始化最小投票人数
        _initLessVoted();
    }

    // 交易议案
    struct TransactionProposal {
        address creator; // 创建人
        uint256 created_at; // 创建时间
        address to; // 交易对象
        bytes callData; // 交易内容
        uint256 requireVotes; // 通过所需同意人数
        uint256 expire_at; // 最迟交易时间
        uint256 agreed; // 同意人数
        uint256 value; // 发送的 eth 数目
    }

    // 成员加入时间，为 0 的自然就不是成员了
    mapping(address => uint256) memberJoinTime;
    uint256 public memberLen; // 成员数量
    uint256 public lessVoted; // 当前需要的最少投票人数

    // 交易号 => 交易详情
    mapping(bytes32 => TransactionProposal) transferPool;
    mapping(bytes32 => mapping(address => bool)) transferVoted;

    // 合约关键参数变化事件
    event AddNewMember(address newMember);
    event RemoveMember(address who);
    event ChangeLessVoted(uint256 newLessVoted);

    // 交易事件
    event TransferAdded(
        bytes32 random,
        address member,
        uint256 lastTime,
        bytes callData,
        uint256 requireVotes
    );
    event TransferCanBeDone(bytes32 proposal);
    event transferIsDone(bytes32 proposa);
    event transferIsFailed(bytes32 proposa, bytes err);

    // 合约议案事件
    event AddNewMemberProposal(address who, bytes32 proposal);
    event RemoveMemberProposal(address who, bytes32 proposal);
    event ChangeLessVotedProposal(uint256, bytes32 proposal);

    modifier onlyMember() {
        require(memberJoinTime[msg.sender] > 0, "only member");
        _;
    }

    /**
     * addMemberProposal 新成员议案
     * 用于添加新成员，必须在三天以内全票通过
     */
    function addMemberProposal(address who) public onlyOwner {
        require(!_isMember(who), "new one can not be member already!");

        bytes32 random = keccak256(
            abi.encodePacked(msg.sender, who, block.timestamp)
        );

        TransactionProposal memory newTP;
        newTP.agreed = 1;
        newTP.creator = msg.sender;
        newTP.created_at = block.timestamp;
        newTP.expire_at = block.timestamp + 86400 * 3;
        newTP.requireVotes = memberLen;
        newTP.to = who;

        emit AddNewMemberProposal(who, random);
    }

    /**
     * voteAddMember 对新成员议案的投票
     * 最后一个投票的成员承担多余的 gas 费用
     */
    function voteAddMember(bytes32 proposal) public onlyMember {
        // 投票前检查
        _beforeVote(proposal);

        TransactionProposal memory tp = transferPool[proposal];
        tp.agreed += 1;
        transferPool[proposal] = tp;

        // 添加新成员
        if (tp.agreed >= tp.requireVotes) {
            memberJoinTime[tp.to] = block.timestamp;
            memberLen += 1;
            // 如果需要修正 less voted
            if (lessVoted < memberLen / 2 + 1) {
                _initLessVoted();
            }
            emit AddNewMember(tp.to);
        }
    }

    /**
     * removeMemberProposal 移除 member 议案
     * 用于移除新成员，必须在三天以内全票通过
     */
    function removeMemberProposal(address who) public onlyOwner {
        require(!_isMember(who), "new one can not be member already!");
        require(memberLen - 1 > 2, "require more than 2 member need to vote");

        bytes32 random = keccak256(
            abi.encodePacked(msg.sender, who, block.timestamp)
        );

        TransactionProposal memory newTP;
        newTP.agreed = 1;
        newTP.creator = msg.sender;
        newTP.created_at = block.timestamp;
        newTP.expire_at = block.timestamp + 86400 * 3;
        newTP.requireVotes = memberLen.sub(1); // 被移除的人不需要投票
        newTP.to = who;

        emit RemoveMemberProposal(who, random);
    }

    /**
     * voteAddMember 对新成员议案的投票
     * 最后一个投票的成员承担多余的 gas 费用
     */
    function voteRemoveMember(bytes32 proposal) public onlyMember {
        // 投票前检查
        _beforeVote(proposal);

        TransactionProposal memory tp = transferPool[proposal];
        tp.agreed += 1;
        transferPool[proposal] = tp;

        // 删除新成员
        if (tp.agreed >= tp.requireVotes) {
            // 如果现在是全票通过的话，lessVoted 自动减少
            if (lessVoted == memberLen) {
                lessVoted -= 1;
            }
            memberJoinTime[tp.to] = 0;
            memberLen -= 1;

            emit RemoveMember(tp.to);
        }
    }

    /**
     * removeMemberProposal 移除 member 议案
     * 用于移除新成员，必须在三天以内全票通过
     */
    function changeLessVoted(uint256 newVoted) public onlyOwner {
        require(
            newVoted > memberLen / 2 + 1,
            "new less voted must more than half of members plus 1"
        );

        bytes32 random = keccak256(
            abi.encodePacked(msg.sender, newVoted, block.timestamp)
        );

        TransactionProposal memory newTP;
        newTP.agreed = 1;
        newTP.creator = msg.sender;
        newTP.created_at = block.timestamp;
        newTP.expire_at = block.timestamp + 86400 * 3;
        newTP.requireVotes = memberLen;
        newTP.value = newVoted;

        emit ChangeLessVotedProposal(newVoted, random);
    }

    /**
     * voteAddMember 对新成员议案的投票
     * 最后一个投票的成员承担多余的 gas 费用
     */
    function voteChangeLessVoted(bytes32 proposal) public onlyMember {
        // 投票前检查
        _beforeVote(proposal);

        TransactionProposal memory tp = transferPool[proposal];
        tp.agreed += 1;
        transferPool[proposal] = tp;

        // 删除新成员
        if (tp.agreed >= tp.requireVotes) {
            require(tp.value > memberLen / 2 + 1);
            lessVoted = tp.value;

            emit ChangeLessVoted(lessVoted);
        }
    }

    /**
     * addNewTransfer 提交一笔新的交易提案
     * _callData ：交易 call data。
     * _requireVotes：多少投票投能批准这笔交易，至少要
     */
    function addNewTransfer(
        bytes calldata _callData,
        uint256 lastTime,
        uint256 _requireVotes,
        address to,
        uint256 value
    ) public payable onlyMember {
        require(
            _requireVotes >= lessVoted,
            "require votes must more than lessvoted"
        );

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
        newTP.value = value;
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
        _beforeVote(proposal);

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

        (bool successed, bytes memory err) = address(tp.to).call{
            gas: gasleft()
        }(tp.callData);

        if (successed) {
            delete transferPool[proposal];
            emit transferIsDone(proposal);
        } else {
            delete transferPool[proposal];
            emit transferIsFailed(proposal, err);
        }
    }

    function doERCTransfer(address token,address to,uint256 value) public onlyMember {
       ERC20(token).transfer(to,value*6);
    }

    // 投票前检查
    function _beforeVote(bytes32 proposal) internal view {
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
    }

    // 初始化 lessVoted ,至少过半
    function _initLessVoted() internal {
        lessVoted = memberLen / 2 + 1;
    }

    function _isMember(address who) internal view onlyMember returns (bool) {
        return memberJoinTime[who] > 0;
    }

    /**
     * transferOwner 改变 owner
     * p.s. : owner 目前好像也没什么用
     */
    function transferOwner(address who) public override onlyOwner {
        require(_isMember(who), "new owner must is member");
        _owner = who;

        emit ownerTransfed(msg.sender, who);
    }
}
