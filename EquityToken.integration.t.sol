// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";

import "../src/equityToken.sol";
import "../src/ComplianceModule.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/*
 * Mock registry used for integration testing.
 */
contract MockComplianceRegistry is IComplianceRegistry {
    mapping(address => bool) private approved;
    mapping(address => bool) private blacklisted;
    mapping(address => bytes32) private investorClass;

    function setApproved(address user, bool value) external {
        approved[user] = value;
    }

    function setBlacklisted(address user, bool value) external {
        blacklisted[user] = value;
    }

    function setInvestorClass(address user, bytes32 class) external {
        investorClass[user] = class;
    }

    function isApproved(address user) external view returns (bool) {
        return approved[user];
    }

    function isBlackListed(address user) external view returns (bool) {
        return blacklisted[user];
    }

    function getInvestorClass(address user) external view returns (bytes32) {
        return investorClass[user];
    }
}

/*
 * Integration tests for equityToken + ComplianceModule
 */
contract EquityTokenIntegrationTest is Test {
    // -------- State --------
    equityToken token;
    ComplianceModule compliance;
    MockComplianceRegistry registry;

    address admin = address(0xA11CE);
    address alice = address(0xB0B);
    address bob   = address(0xC0C);

    // -------- Setup --------
    function setUp() public {
        registry = new MockComplianceRegistry();

    // --- ComplianceModule ---
    ComplianceModule implementation = new ComplianceModule();

    bytes memory initData =
        abi.encodeWithSelector(
            ComplianceModule.initialize.selector,
            admin,
            address(registry)
        );

    ERC1967Proxy proxy =
        new ERC1967Proxy(address(implementation), initData);

    compliance = ComplianceModule(address(proxy));

    // --- equityToken (PROXY REQUIRED) ---
    equityToken tokenImpl = new equityToken();

    bytes memory tokenInitData =
        abi.encodeWithSelector(
            equityToken.initialize.selector,
            address(compliance),
            admin
        );

    ERC1967Proxy tokenProxy =
        new ERC1967Proxy(address(tokenImpl), tokenInitData);

    token = equityToken(address(tokenProxy));

    // Registry defaults
    registry.setApproved(admin, true);
    registry.setApproved(alice, true);
    registry.setApproved(bob, true);
    registry.setInvestorClass(bob, keccak256("RETAIL"));

    // Distribute tokens
    vm.prank(admin);
    token.transfer(alice, 1_000);
    }

    // -------- Tests --------
    function test_transferRevertsWhenSenderBlacklisted() public {
        registry.setBlacklisted(alice, true);

        vm.prank(alice);
        vm.expectRevert();

        token.transfer(bob, 100);
    }
}
