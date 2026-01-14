// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IUUPSProxy {
    function upgradeTo(address newImplementation) external;
}

/// @title UpgradeAuthority
/// @notice Governs upgrades for UUPS proxies
contract UpgradeAuthority is Ownable {

    uint256 public upgradeDelay;

    mapping(address => bool) public upgradesFrozen;
    mapping(address => address) public pendingImplementation;
    mapping(address => uint256) public upgradeEta;

    event UpgradeDelaySet(uint256 delay);
    event UpgradeScheduled(address indexed proxy, address indexed implementation, uint256 eta);
    event UpgradeExecuted(address indexed proxy, address indexed implementation);
    event UpgradesFrozen(address indexed proxy);
    event UpgradesUnfrozen(address indexed proxy);

    /// @notice OZ v5 requires initialOwner
    constructor(address initialOwner) Ownable(initialOwner) {}

    function setUpgradeDelay(uint256 delaySeconds) external onlyOwner {
        upgradeDelay = delaySeconds;
        emit UpgradeDelaySet(delaySeconds);
    }

    function scheduleUpgrade(address proxy, address implementation)
        external
        onlyOwner
    {
        require(!upgradesFrozen[proxy], "Upgrades frozen");
        require(implementation != address(0), "Invalid implementation");

        uint256 eta = block.timestamp + upgradeDelay;

        pendingImplementation[proxy] = implementation;
        upgradeEta[proxy] = eta;

        emit UpgradeScheduled(proxy, implementation, eta);
    }

    function executeUpgrade(address proxy)
        external
        onlyOwner
    {
        require(!upgradesFrozen[proxy], "Upgrades frozen");

        address implementation = pendingImplementation[proxy];
        require(implementation != address(0), "No upgrade scheduled");
        require(block.timestamp >= upgradeEta[proxy], "Timelock active");

        IUUPSProxy(proxy).upgradeTo(implementation);

        emit UpgradeExecuted(proxy, implementation);

        pendingImplementation[proxy] = address(0);
        upgradeEta[proxy] = 0;
    }

    function freezeUpgrades(address proxy) external onlyOwner {
        upgradesFrozen[proxy] = true;
        emit UpgradesFrozen(proxy);
    }

    function unfreezeUpgrades(address proxy) external onlyOwner {
        upgradesFrozen[proxy] = false;
        emit UpgradesUnfrozen(proxy);
    }
}
