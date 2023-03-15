// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./IPegETH.sol";

contract PegETH is IPegETH, AccessControlUpgradeable, PausableUpgradeable {
    // roles
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    ERC20 private ERC20interface;
    address public tokenAdress; // This is the token address
    //address public ownTokenAdress; // This is the token address
    mapping(address => bool) public validators;
    uint32 public validatorCount;
    mapping(address => bool) public operators;
    uint32 public operatorCount;
    uint32 public minValidator;
    mapping(bytes32 => mapping(address => bool)) public approvals;
    mapping(bytes32 => uint32) public approvalCount;
    uint256 public fee;

    /**
     * @dev set USDC {_tokenAdress}, SUSD {_ownTokenAddress}
     * and init default params for contract
     */
    function initialize(address _tokenAdress)
        external
        initializer
    {
        // USDC address
        tokenAdress = _tokenAdress;
        ERC20interface = ERC20(tokenAdress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        minValidator = 3;
        fee = 0;
        __Pausable_init();
    }

    /**
     * @dev check contract balance
     */
    function contractBalance() public view override returns (uint256 _amount) {
        return ERC20interface.balanceOf(address(this));
    }

    /**
     * @dev deposit usdc from ETH chain to  asset chain
     * params: {_amount}
     * Emit {Deposit}
     * Require approve for SC to transfer ERC20
     */
    function deposit(uint256 _amount) external override whenNotPaused {
        address fromAddress = msg.sender;
        address to = address(this);
        ERC20interface.transferFrom(fromAddress, to, _amount);
        emit Deposit(fromAddress, to, _amount);
    }

    /**
     * @dev add validator {_validator}
     * Requirements:
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     * Emit {AddValidator}
     */
    function addValidator(address _validator)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(!validators[_validator], "PegETH: This validator is existed!");
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
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            validators[_validator],
            "PegETH: This validator is not existed!"
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

    function _getMessageHash(
        address _to,
        uint _amount,
        bytes32 _txId
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _txId));
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
        bytes memory signature
    ) private pure returns (bool) {
        bytes32 messageHash = _getMessageHash(_to, _amount, _txId);
        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(messageHash);

        return _recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    /**
     * @dev Vote transfer USDC and SUSD to individual account on ETh chain from Asset chain only one tx vote
     * params: {_to}, {_amount}, {_txId}
     * - {_to}: receiver address on
     * - {_txId}: txhash on Asset chain
     * - {_signatures}: sign on sha3 (_to, _amount, _txId)
     * - {_signers}: signer for each signature 
     * When have enough votes, it emits {Withdraw}
     * Requirements:
     * - the caller must have the `OPERATOR_ROLE`.
     */
    function voteTransferOneShot(
        address _to,
        uint256 _amount,
        bytes32 _txId,
        bytes[] calldata _signatures,
        address[] calldata _signers
    ) external override whenNotPaused onlyRole(OPERATOR_ROLE){
        require(_amount > fee, "Do not have enough balance");
        bytes32 txId = keccak256(abi.encodePacked(_to, _amount, _txId));
        for(uint i = 0 ; i < _signatures.length ; i++){
            if(validators[_signers[i]] 
                && !approvals[txId][_signers[i]]
                && _verify(_signers[i], _to, _amount, _txId, _signatures[i])){
                approvalCount[txId] += 1;
                approvals[txId][_signers[i]] = true;
                if (approvalCount[txId] == minValidator) {
                    uint256 csBalance = contractBalance();
                    uint256 transferBalance = _amount - fee;
                    require(csBalance > transferBalance, "Do not have enough balance");
                    ERC20interface.transfer(_to, transferBalance);
                    emit Withdraw(address(this), _to, transferBalance, _txId);
                }
            }
        }
    }

     /**
     * @dev claim by user USDC and SUSD to individual account on ETh chain from Asset chain only one tx vote
     * params: {_amount}, {_txId}
     * - {_txId}: txhash on Asset chain
     * - {_signatures}: sign on sha3 (_to, _amount, _txId)
     * - {_signers}: signer for each signature 
     * When have enough votes, it emits {Withdraw}
     */
    function claim(
        uint256 _amount,
        bytes32 _txId,
        bytes[] calldata _signatures,
        address[] calldata _signers
    ) external override whenNotPaused {
        require(_amount > fee, "Do not have enough balance");
        address _to = msg.sender;
        bytes32 txId = keccak256(abi.encodePacked(_to, _amount, _txId));
        for(uint i = 0 ; i < _signatures.length ; i++){
            if(validators[_signers[i]] 
                && !approvals[txId][_signers[i]]
                && _verify(_signers[i], _to, _amount, _txId, _signatures[i])){
                approvalCount[txId] += 1;
                approvals[txId][_signers[i]] = true;
                if (approvalCount[txId] == minValidator) {
                    uint256 csBalance = contractBalance();
                    uint256 transferBalance = _amount - fee;
                    require(csBalance >= transferBalance, "Do not have enough balance");
                    ERC20interface.transfer(_to, transferBalance);
                    emit Withdraw(address(this), _to, transferBalance, _txId);
                }
            }
        }
    }

    // fee for validator
    function setFee(uint256 _fee) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        fee = _fee;
    }

    function getFee() public view override returns (uint256) {
        return fee;
    }

    /**
     * @dev Set USDC address needs {_tokenAddress}
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
        ERC20interface = ERC20(tokenAdress);
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
            "PegETH: must have pauser role to pause"
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
            "PegETH: must have pauser role to unpause"
        );
        _unpause();
    }
}
