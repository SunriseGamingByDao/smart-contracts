// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SUSD.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./IPegBurn.sol";

contract PegBurn is IPegBurn, AccessControlUpgradeable, PausableUpgradeable {
    // roles
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    SUSD private ERC20interface;
    address public tokenAdress; // This is the token address
    uint32 public validatorCount;
    uint32 public minValidator;
    mapping(address => bool) public operators;
    uint32 public operatorCount;
    mapping(address => bool) public validators;
    mapping(bytes32 => mapping(address => bool)) public approvals;
    mapping(bytes32 => uint32) public approvalCount;
    mapping(bytes32 => mapping(address => bool)) public approvalMints;
    mapping(bytes32 => uint32) public approvalMintCount;

    mapping(address => address) public ethToBurnAddress;
    mapping(address => address) public burnToEthAddress;

    /**
     * @dev set SUSD {_tokenAdress} and init default params for contract
     */
    function initialize(address _tokenAdress) public initializer {
        // USDT address
        tokenAdress = _tokenAdress;
        ERC20interface = SUSD(tokenAdress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        minValidator = 3;
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
        require(!validators[_validator], "PegBurn: This validator is existed!");
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
            "PegBurn: This validator is not existed!"
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
    function setMinValidator(uint32 min)
        public
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        minValidator = min;
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
     * @dev Vote mint SUSD to individual account on Asset chain from ETH chain
     * params: {_to}, {_amount}, {_txId}
     * - {_to}: receiver address on
     * - {_txId}: txhash on ETH chain
     * Emit {VoteMintOnAssetChain}
     * When have enough votes, it emits {MintOnAssetChain}
     * Requirements:
     * - the caller must have the `VALIDATOR_ROLE`.
     */
    function voteMintOnAssetChain(
        address _to,
        uint256 _amount,
        bytes32 _txId
    ) public override whenNotPaused onlyRole(VALIDATOR_ROLE) {
        bytes32 txId = keccak256(abi.encodePacked(_to, _amount, _txId));
        require(
            !approvalMints[txId][msg.sender],
            "PegBurn: This validator voted!"
        );
        approvalMints[txId][msg.sender] = true;
        approvalMintCount[txId] += 1;
        emit VoteMintOnAssetChain(msg.sender, _to, _amount, _txId);
        if (approvalMintCount[txId] == minValidator) {
            ERC20interface.mint(_to, _amount);
            emit MintOnAssetChain(address(this), _to, _amount, _txId);
        }
    }
    
    /**
     * @dev withdraw {_amount} susd from asset chain to ETH chain
     * Emit {WithdrawOnETH}
     */
    function withdrawOnETH(uint256 _amount) external override whenNotPaused {
        address fromAddress = msg.sender;
        uint256 clientBalance = ERC20interface.balanceOf(fromAddress);
        require(
            clientBalance >= _amount,
            "PegBurn: transfer amount exceeds balance"
        );

        ERC20interface.burnFromSC(fromAddress, _amount);
        emit WithdrawOnEth(fromAddress, _amount);
    }

     /**
     * @dev Set pair address: {_eth}, {_burn}
     * to map from ETH to Burn platform
     * Emit {RegisterPairAddressByUser}
     */

    function registerPairAddress(address _eth, bytes memory signature)
        public
        override
        whenNotPaused
    {
        bytes32 messageHash = keccak256(abi.encodePacked(_eth, msg.sender));
        bytes32 ethSignedMessageHash = keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
            );
        require(_recoverSigner(ethSignedMessageHash, signature) == _eth, "PegBurn: wrong signature");
        ethToBurnAddress[_eth] = msg.sender;
        burnToEthAddress[msg.sender] = _eth;
        emit RegisterPairAddress(_eth, msg.sender);
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

    function _getMessageHash(
        address _to,
        uint _amount,
        bytes32 _txId
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _txId));
    }

    function _verify(
        address _signer,
        address _to,
        uint _amount,
        bytes32 _txId,
        bytes memory signature
    ) private pure returns (bool) {
        bytes32 messageHash = _getMessageHash(_to, _amount, _txId);
        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(messageHash);

        return _recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

     /**
     * @dev Vote mint SUSD to individual account on Asset chain from ETH chain
     * params: {_to}, {_amount}, {_txId}
     * - {_to}: receiver address on
     * - {_txId}: txhash on ETH chain
     * - {_signatures}: sign on sha3 (_to, _amount, _txId)
     * - {_signers}: signer for each signature 
     * When have enough votes, it emits {MintOnAssetChain}
     * Requirements:
     * - the caller must have the `OPERATOR_ROLE`.
     */

    function voteMintOnAssetChainOneShot(
        address _to,
        uint256 _amount,
        bytes32 _txId,
        bytes[] calldata _signatures,
        address[] calldata _signers
    ) public override whenNotPaused onlyRole(OPERATOR_ROLE) {
        bytes32 txId = keccak256(abi.encodePacked(_to, _amount, _txId));
        for(uint i = 0 ; i < _signatures.length ; i++){
            if(validators[_signers[i]] 
                && !approvalMints[txId][_signers[i]]
                && _verify(_signers[i], _to, _amount, _txId, _signatures[i])){
                approvalMints[txId][_signers[i]] = true;
                approvalMintCount[txId] += 1;
                if (approvalMintCount[txId] == minValidator) {
                    ERC20interface.mint(_to, _amount);
                    emit MintOnAssetChain(address(this), _to, _amount, _txId);
                }
            }
        }
    }

    /**
     * @dev get pair address by {_eth} address
     */
    function getPairAddressByETH(address _eth)
        public
        view
        override
        returns (address)
    {
        return ethToBurnAddress[_eth];
    }

    /**
     * @dev get pair address by {_burn} address
     */
    function getPairAddressByBurn(address _burn)
        public
        view
        override
        returns (address)
    {
        return burnToEthAddress[_burn];
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
            "PegBurn: must have pauser role to pause"
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
            "PegBurn: must have pauser role to unpause"
        );
        _unpause();
    }
}
