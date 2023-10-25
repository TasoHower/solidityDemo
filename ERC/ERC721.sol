// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* 
    ERC-721 协标准接口
*/
abstract contract ERC721 {
    function balanceOf(address _owner) external view virtual returns (uint256);

    function ownerOf(uint256 _tokenId) external view virtual returns (address);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) external payable virtual;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable virtual;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable virtual;

    function approve(
        address _approved,
        uint256 _tokenId
    ) external payable virtual;

    function setApprovalForAll(
        address _operator,
        bool _approved
    ) external virtual;

    function getApproved(
        uint256 _tokenId
    ) external view virtual returns (address);

    function isApprovedForAll(
        address _owner,
        address _operator
    ) external view virtual returns (bool);

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );
}
