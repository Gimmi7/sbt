// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./LogicStorage.sol";
import "./SBT721Upgradeable.sol";

contract SBT is
    Initializable,
    SBT721Upgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    LogicStorage
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __SBT721_init("ShareSBT", "ShareSBT");
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        // grant role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }

    function pause() public onlyOwner onlyProxy {
        _pause();
    }

    function unpause() public onlyOwner onlyProxy {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
        onlyProxy
    {}

    function _acceccControl(bytes4 selector)
        internal
        view
        override
        whenNotPaused
    {
        if (
            SBT721Upgradeable.revoke.selector == selector ||
            SBT721Upgradeable.attest.selector == selector
        ) {
            super._checkRole(OPERATOR_ROLE);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable, SBT721Upgradeable)
        returns (bool)
    {
        return
            AccessControlUpgradeable.supportsInterface(interfaceId) ||
            SBT721Upgradeable.supportsInterface(interfaceId);
    }

    function setBaseTokenURI(string calldata uri) public onlyOwner onlyProxy {
        _baseURI = uri;
    }
}
