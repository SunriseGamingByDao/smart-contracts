// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISUSD.sol";

import {ERC20PresetMinterPauserUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";

contract SUSD is ISUSD, ERC20PresetMinterPauserUpgradeable {
    bytes32 public constant BURNER_FROM_SC_ROLE =
        keccak256("BURNER_FROM_SC_ROLE");
    bytes32 public constant TRANSFER_TO_SC_ROLE =
        keccak256("TRANSFER_TO_SC_ROLE");
    uint8 private _decimals;

    /**
     * @dev init {name}, {symbol}, {decimals} for ERC20 token
     */
    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public initializer {
        ERC20PresetMinterPauserUpgradeable.__ERC20PresetMinterPauser_init(
            name,
            symbol
        );
        _decimals = decimals;
    }

    /**
     * @dev get decimals
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev SC transfer {amount} token from {sender} to {recipient}
     * Requirements:
     * - the caller must have the `TRANSFER_TO_SC_ROLE`.
     */
    function transferToSC(
        address sender,
        address recipient,
        uint256 amount
    ) public override onlyRole(TRANSFER_TO_SC_ROLE) {
        _transfer(sender, recipient, amount);
    }

    /**
     * @dev assign Transfer permission for {sc}
     * Requirements:
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function transferToSCAssign(address sc)
        public
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setupRole(TRANSFER_TO_SC_ROLE, sc);
    }

    /**
     * @dev check Transfer permission for {sc}
     */
    function transferToSCHasRole(address sc)
        public
        view
        override
        returns (bool)
    {
        return hasRole(TRANSFER_TO_SC_ROLE, sc);
    }

    /**
     * @dev SC burn {amount} token from {reciever}
     * Requirements:
     * - the caller must have the `BURNER_FROM_SC_ROLE`.
     */
    function burnFromSC(address reciever, uint256 amount)
        public
        override
        onlyRole(BURNER_FROM_SC_ROLE)
    {
        _burn(reciever, amount);
    }

    /**
     * @dev assign Burn permission for {sc}
     * Requirements:
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function burnFromSCAssign(address burner)
        public
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setupRole(BURNER_FROM_SC_ROLE, burner);
    }

    /**
     * @dev check Burn permission for {sc}
     */
    function burnFromSCHasRole(address burner)
        public
        view
        override
        returns (bool)
    {
        return hasRole(BURNER_FROM_SC_ROLE, burner);
    }
}
