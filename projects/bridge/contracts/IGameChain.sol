// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGameChain {
    event WithdrawOnAssetChain(address indexed _from, uint256 _value);
    event MintOnGameChain(
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes32 _txId,
        uint256 _gameChainId
    );

    event VoteMintOnGameChain(
        address indexed _validator,
        address _to,
        uint256 _amount,
        bytes32 _txId,
        uint256 _gameChainId
    );
    event AddValidator(address _validator);
    event RevokeValidator(address _validator);
    event SetTokenAddress(address _tokenAddress);
    event AddOperator(address _operator);
    event RevokeOperator(address _operator);

    function addValidator(address _validator) external;

    function revokeValidator(address _validator) external;

    function setMinValidator(uint32 _min) external;

    function getMinValidator() external view returns (uint32);

    function getValidatorCount() external view returns (uint32);

    function checkExistValidator(address _validator)
        external
        view
        returns (bool);

    function addOperator(address _operator) external;

    function revokeOperator(address _operator) external;

    function checkExistOperator(address _operator)
        external
        view
        returns (bool);

    function voteMintOnGameChain(
        address _to,
        uint256 _amount,
        bytes32 _txId,
        uint256 _gameChainId
    ) external;

    function voteMintOnGameChainOneShot(
        address _to,
        uint256 _amount,
        bytes32 _txId,
        uint256 _gameChainId,
        bytes[] calldata _signatures,
        address[] calldata _signers
    ) external;

    function withdrawOnAssetChain(uint256 _amount) external;
    function withdrawOnAssetChainWithSpecifiedRecipient(address _recipient, uint256 _amount) external;

    // set SUSD address again
    function setTokenAddress(address _tokenAddress) external;

    function getTokenAddress() external view returns (address);

    function pause() external;

    function unpause() external;
}
