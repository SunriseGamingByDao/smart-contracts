// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAssetChain {
    event DepositGameChain(
        address indexed _from,
        uint256 _value,
        uint256 _gameChainId
    );
    event VoteRefundOnAssetChain(
        address indexed validator,
        address _to,
        uint256 _amount,
        bytes32 _txId,
        uint256 _gameChainId
    );
    event RefundOnAssetChain(
        address indexed _from,
        address indexed _to,
        uint256 _value,
        uint256 _gameChainId,
        bytes32 _txId
    );
    event AddValidator(address validator);
    event RevokeValidator(address validator);
    event SetTokenAddress(address _tokenAddress);
    event AddOperator(address _operator);
    event RevokeOperator(address _operator);

    function contractBalance() external view returns (uint256 _amount);

    function depositGameChain(uint256 _amount, uint256 _gameChainId) external;

    // peg
    // manage validator
    function addValidator(address _validator) external;

    function revokeValidator(address _validator) external;

    function getValidatorCount() external view returns (uint32);

    function checkExistValidator(address _validator)
        external
        view
        returns (bool);

    function setMinValidator(uint32 _min) external;

    function getMinValidator() external view returns (uint32);

      function addOperator(address _operator) external;

    function revokeOperator(address _operator) external;

    function checkExistOperator(address _operator)
        external
        view
        returns (bool);

    // vote
    function voteRefundOnAssetChain(
        uint256 _gameChainId,
        address _to,
        uint256 _amount,
        bytes32 _txId
    ) external;

    function voteRefundOnAssetChainOnShot(
        uint256 _gameChainId,
        address _to,
        uint256 _amount,
        bytes32 _txId,
        bytes[] calldata _signatures,
        address[] calldata _signers
    ) external;

    // set SUSD address again
    function setTokenAddress(address _tokenAddress) external;

    function getTokenAddress() external view returns (address);

    function pause() external;

    function unpause() external;
}
