// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPegBurn {
    event WithdrawOnEth(address indexed _from, uint256 _value);
    event MintOnAssetChain(
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes32 _txId
    );
    event VoteMintOnAssetChain(
        address indexed validator,
        address _to,
        uint256 _amount,
        bytes32 _txId
    );
    event AddValidator(address _validator);
    event RevokeValidator(address _validator);
     event AddOperator(address _operator);
    event RevokeOperator(address _operator);
    event RegisterPairAddress(address _eth, address _burn);
    event SetTokenAddress(address _tokenAddress);

    function addValidator(address _validator) external;

    function revokeValidator(address _validator) external;

    function setMinValidator(uint32 min) external;

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

    function voteMintOnAssetChain(
        address _to,
        uint256 _amount,
        bytes32 _txId
    ) external;

     function voteMintOnAssetChainOneShot(
        address _to,
        uint256 _amount,
        bytes32 _txId,
        bytes[] calldata _signatures,
        address[] calldata _signers
    ) external;

    function withdrawOnETH(uint256 _amount) external;

    function getPairAddressByETH(address _eth) external view returns (address);

    function getPairAddressByBurn(address _burn)
        external
        view
        returns (address);

    // set SUSD address again
    function setTokenAddress(address _tokenAddress) external;

    function getTokenAddress() external view returns (address);

    function pause() external;

    function unpause() external;

    function registerPairAddress(address _eth, bytes memory signature) external;
}
