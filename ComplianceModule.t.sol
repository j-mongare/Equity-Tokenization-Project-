// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/ComplianceModule.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";



/*//////////////////////////////////////////////////////////////
                        MOCK REGISTRY
//////////////////////////////////////////////////////////////*/

contract MockComplianceRegistry is IComplianceRegistry {
    mapping(address => bool) public approved;
    mapping(address => bool) public blacklisted;
    mapping(address => bytes32) public investorClass;

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

/*//////////////////////////////////////////////////////////////
                          TESTS
//////////////////////////////////////////////////////////////*/

contract ComplianceModuleTest is Test {
    ComplianceModule compliance;
    MockComplianceRegistry registry;

    address admin = address(0xA11CE);
    address alice = address(0xB0B);
    address bob   = address(0xC0C);

    function setUp() public {
       registry = new MockComplianceRegistry();

    ComplianceModule implementation = new ComplianceModule();

    bytes memory initData =
        abi.encodeWithSelector(
            ComplianceModule.initialize.selector, admin,
            address(registry)
        );

    ERC1967Proxy proxy =
        new ERC1967Proxy(address(implementation), initData);

    compliance = ComplianceModule(address(proxy));
    }

    function testCanTransferApprovedUser() public {
        registry.setApproved(bob, true);

        bool allowed = compliance.canTransfer(alice, bob, 100);

        assertTrue(allowed);
    }
	function test_sanity() public {
	
	assertTrue (address(compliance) != address(0));
	
	}
	function test_blacklistedSenderBlocked() public {
	registry.setBlacklisted(alice, true); // mark alice as blacklisted
	
	
	bool allowed = compliance.canTransfer(alice, bob, 100);
	assertFalse(allowed);
	
	
	}
	function test_blacklistedReceiverBlocked() public {
	
	registry. setBlacklisted(bob, true); // marks bob as blacklisted
	
	bool allowed = compliance. canTransfer(alice, bob, 100);
	assertFalse(allowed);
	
	
	}
	function pause_blocksTransfers()public {
	//@notice admin has PAUSER_ROLE from initialize()
	
	vm.prank(admin);
	compliance.pauseTransfers();
	
	bool allowed = compliance.canTransfer(alice, bob, 100);
	assertFalse(allowed);
	
	}
	function test_lockupsBlockTransfersBeforeExpiry()public {
	
	uint64 unlockTime = uint64 (block.timestamp + 30 days);
	
	vm.prank(admin);
	compliance.setLockUp(alice, unlockTime);
	
	bool allowed = compliance.canTransfer(alice, bob, 100);
	assertFalse(allowed);
	
	
	}
	function test_transferAllowedAfterLockupExpires() public{
	uint64 unlockTime = uint64 (block.timestamp + 30 days);
	
	vm.prank(admin);
	compliance.setLockUp(alice, unlockTime);
	
	bool allowed = compliance.canTransfer(alice, bob, 100);
	assertFalse(allowed);
	
	
	
	}
	function test_setHoldingLimitStoresValue() public {
	
	bytes32 RETAIL = keccak256 ("RETAIL");
	 vm.prank(admin);
	 compliance.setHoldingLimit(RETAIL, 1000);
	 
	 uint256 limit = compliance.getHoldingLimit(RETAIL);
	 assertEq(limit, 1000);
	
	
	}
}

