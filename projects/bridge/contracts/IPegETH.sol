// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPegETH {
    event Deposit(address indexed _from, address indexed _to, uint256 _value);
    event Withdraw(
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes32 _txId
    );
    event Swap(address indexed _from, address indexed _to, uint256 _value);
    event VoteTransfer(
        address indexed validator,
        address _to,
        uint256 _amount,
        bytes32 _txId
    );
    event AddValidator(address _validator);
    event RevokeValidator(address _validator);
    event AddOperator(address _operator);
    event RevokeOperator(address _operator);
    event SetFee(uint256 _fee);
    event SetTokenAddress(address _tokenAddress);
    event SetOwnTokenAddress(address _tokenAddress);

    function contractBalance() external view returns (uint256 _amount);

    function deposit(uint256 _amount) external;

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

    function voteTransferOneShot(
        address _to,
        uint256 _amount,
        bytes32 _txId,
        bytes[] calldata _signatures,
        address[] calldata _signers
    ) external;

    // fee for validator
    function setFee(uint256 _fee) external;

    function getFee() external view returns (uint256);

    // set USDC address again
    function setTokenAddress(address _tokenAddress) external;

    function getTokenAddress() external view returns (address);

    function pause() external;

    function unpause() external;

    function claim(
        uint256 _amount,
        bytes32 _txId,
        bytes[] calldata _signatures,
        address[] calldata _signers
    ) external ;
}
