// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SUSD.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./IGameChain.sol";

contract GameChain is
    IGameChain,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    // roles
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    SUSD private ERC20interface;
    address public tokenAdress; // This is the token address
    mapping(address => bool) public validators;
    uint32 public validatorCount;
    uint32 public minValidator;
    mapping(address => bool) public operators;
    uint32 public operatorCount;
    mapping(bytes32 => mapping(address => bool)) public approvals;
    mapping(bytes32 => uint32) public approvalCount;
    mapping(bytes32 => mapping(address => bool)) public approvalMints;
    mapping(bytes32 => uint32) public approvalMintCount;

    /**
     * @dev set SUSD {_tokenAdress} and init default params for contract
     */
    function initialize(address _tokenAdress) public initializer {
        // USDT address
        tokenAdress = _tokenAdress;
        ERC20interface = SUSD(tokenAdress);
        minValidator = 3;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __Pausable_init();
    }

    /**
     * @dev add validator {_validator}
     * Requirements:
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     * Emit {AddValidator}
     */
    function addValidator(address _validator)
        public
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            !validators[_validator],
            "Gamechain: This validator is existed!"
        );
        validators[_validator] = true;
        _setupRole(VALIDATOR_ROLE, _validator);
        validatorCount += 1;
        emit AddValidator(_validator);
    }

    /**
     * @dev revoke validator {_validator}
     * Requirements:
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     * Emit {RevokeValidator}
     */
    function revokeValidator(address _validator)
        public
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            validators[_validator],
            "Gamechain: This validator is not existed!"
        );
        revokeRole(VALIDATOR_ROLE, _validator);
        validators[_validator] = false;
        validatorCount -= 1;
        emit RevokeValidator(_validator);
    }

    /**
     * @dev set minimum validators who need vote for actions {_min}
     * Requirements:
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setMinValidator(uint32 _min)
        public
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        minValidator = _min;
    }

    /**
     * @dev check minimum validators who need vote for actions.
     */
    function getMinValidator() public view override returns (uint32) {
        return minValidator;
    }

    /**
     * @dev check number of validator
     */
    function getValidatorCount() public view override returns (uint32) {
        return validatorCount;
    }

    /**
     * @dev check this address {_validator} is validator, isn't it?
     */
    function checkExistValidator(address _validator)
        public
        view
        override
        returns (bool)
    {
        return validators[_validator];
    }

    /**
     * @dev add operator {_operator}
     * Requirements:
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     * Emit {AddOperator}
     */
    function addOperator(address _operator)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(!operators[_operator], "PegETH: This operator is existed!");
        operators[_operator] = true;
        _setupRole(OPERATOR_ROLE, _operator);
        operatorCount += 1;
        emit AddOperator(_operator);
    }

    /**
     * @dev revoke operator {_operator}
     * Requirements:
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     * Emit {RevokeOperator}
     */
    function revokeOperator(address _operator)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            operators[_operator],
            "PegETH: This _operator is not existed!"
        );
        revokeRole(OPERATOR_ROLE, _operator);
        operators[_operator] = false;
        operatorCount -= 1;
        emit RevokeOperator(_operator);
    }

    /**
     * @dev check this address {_operator} is operator, isn't it?
     */
    function checkExistOperator(address _operator)
        public
        view
        override
        returns (bool)
    {
        return operators[_operator];
    }

    /**
     * @dev Vote mint SUSD to individual account on Game chain from Asset chain
     * params: {_to}, {_amount}, {_txId}
     * - {_to}: receiver address on
     * - {_txId}: txhash on Game chain
     * Emit {VoteMintOnGameChain}
     * When have enough votes, it emits {MintOnGameChain}
     * Requirements:
     * - the caller must have the `VALIDATOR_ROLE`.
     */
    function voteMintOnGameChain(
        address _to,
        uint256 _amount,
        bytes32 _txId,
        uint256 _gameChainId
    ) public override onlyRole(VALIDATOR_ROLE) whenNotPaused {
        bytes32 txId = keccak256(abi.encodePacked(_to, _amount, _txId));
        require(
            !approvalMints[txId][msg.sender],
            "Gamechain: This validator voted!"
        );
        approvalMints[txId][msg.sender] = true;
        approvalMintCount[txId] += 1;
        emit VoteMintOnGameChain(msg.sender, _to, _amount, _txId, _gameChainId);
        if (approvalMintCount[txId] == minValidator) {
            ERC20interface.mint(_to, _amount);
            emit MintOnGameChain(address(this), _to, _amount, _txId, _gameChainId);
        }
    }

    function _getMessageHash(
        address _to,
        uint _amount,
        bytes32 _txId,
        uint256 _gameChainId
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _txId, _gameChainId));
    }

    function _getEthSignedMessageHash(bytes32 _messageHash)
        private
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    function _recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature)
        private
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function _verify(
        address _signer,
        address _to,
        uint _amount,
        bytes32 _txId,
        uint256 _gameChainId,
        bytes memory signature
    ) private pure returns (bool) {
        bytes32 messageHash = _getMessageHash(_to, _amount, _txId, _gameChainId);
        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(messageHash);

        return _recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    /**
     * @dev Vote mint SUSD to individual account on Game chain from Asset chain
     * params: {_to}, {_amount}, {_txId}, {_signatures}, {_signers}
     * - {_to}: receiver address on
     * - {_txId}: txhash on Asset chain
     * - {_signatures}: sign on sha3 (_to, _amount, _txId)
     * - {_signers}: signer for each signature 
     * - {_gameChainId}:  id of game chain
     * When have enough votes, it emits {MintOnGameChain}
     * Requirements:
     * - the caller must have the `OPERATOR_ROLE`.
     */
    function voteMintOnGameChainOneShot(
        address _to,
        uint256 _amount,
        bytes32 _txId,
        uint256 _gameChainId,
        bytes[] calldata _signatures,
        address[] calldata _signers
    ) public override onlyRole(OPERATOR_ROLE) whenNotPaused {
        bytes32 txId = keccak256(abi.encodePacked(_to, _amount, _txId, _gameChainId));
        for(uint i = 0 ; i < _signatures.length ; i++){
            if(validators[_signers[i]] 
                && !approvalMints[txId][_signers[i]]
                && _verify(_signers[i], _to, _amount, _txId, _gameChainId, _signatures[i])){
                approvalMints[txId][_signers[i]] = true;
                approvalMintCount[txId] += 1;
                if (approvalMintCount[txId] == minValidator) {
                    ERC20interface.mint(_to, _amount);
                    emit MintOnGameChain(address(this), _to, _amount, _txId, _gameChainId);
                }
            }
        }
    }

    /**
     * @dev withdraw {_amount} susd from game chain to asset chain
     * Emit {WithdrawOnAssetChain}
     */
    function withdrawOnAssetChain(uint256 _amount)
        external
        override
        whenNotPaused
    {
        address fromAddress = msg.sender;
        uint256 clientBalance = ERC20interface.balanceOf(fromAddress);
        require(
            clientBalance >= _amount,
            "Gamechain: transfer amount exceeds balance"
        );

        ERC20interface.burnFromSC(fromAddress, _amount);
        emit WithdrawOnAssetChain(fromAddress, _amount);
    }

    function withdrawOnAssetChainWithSpecifiedRecipient(address _recipient, uint256 _amount)
        external
        override
        whenNotPaused
    {
        address msgSender = _msgSender();

        uint256 balance = ERC20interface.balanceOf(msgSender);

        require(balance >= _amount, "Gamechain: transfer amount exceeds balance");

        ERC20interface.burnFromSC(msgSender, _amount);

        emit WithdrawOnAssetChain(_recipient, _amount);
    }

    /**
     * @dev Set SUSD address needs {_tokenAddress}
     * Emit {SetTokenAddress}
     * Requirements:
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setTokenAddress(address _tokenAddress)
        public
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenAdress = _tokenAddress;
        ERC20interface = SUSD(tokenAdress);
        emit SetTokenAddress(_tokenAddress);
    }

    /**
     * @dev get SUSD address which currently use
     */
    function getTokenAddress() public view override returns (address) {
        return tokenAdress;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public override {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Assetchain: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public override {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Assetchain: must have pauser role to unpause"
        );
        _unpause();
    }
}
