// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/*
    SYSTEM INTEGRATION TEST (NO MOCKS)

    Purpose:
    - Verify equityToken enforces compliance rules
      using REAL production contracts:
        - ComplianceRegistry
        - ComplianceModule
        - equityToken
    - Verify proxy + initializer wiring
    - Verify pause, blacklist, lockup, forced transfer end-to-end

    This answers:
    "Does the system work exactly as deployed?"
*/

import "forge-std/Test.sol";

import "../src/equityToken.sol";
import "../src/ComplianceModule.sol";
import "../src/complianceRegistry.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract EquityTokenSystemTest is Test {
    
//====================== ACTORS=====================================
    

    address admin    = address(0xA11CE);
    address alice    = address(0xBEEF);
    address bob      = address(0xCAFE);
    address attacker = address(0xBAD);

   
   //==================CONTRACTS============================================
    

    equityToken token;
    ComplianceModule compliance;
    ComplianceRegistry registry;

   
   //=========================SETUP==============================================
 

    function setUp() public {
        /* ---------------- ComplianceRegistry ---------------- */

        ComplianceRegistry registryImpl = new ComplianceRegistry();
        bytes memory registryInit =
            abi.encodeWithSelector(
                ComplianceRegistry.initialize.selector,
                admin
            );

        registry = ComplianceRegistry(
            address(new ERC1967Proxy(address(registryImpl), registryInit))
        );

        /* ---------------- ComplianceModule ---------------- */

        ComplianceModule complianceImpl = new ComplianceModule();
        bytes memory complianceInit =
            abi.encodeWithSelector(
                ComplianceModule.initialize.selector,
                admin,
                address(registry)
            );

        compliance = ComplianceModule(
            address(new ERC1967Proxy(address(complianceImpl), complianceInit))
        );

        /* ---------------- equityToken ---------------- */

        equityToken tokenImpl = new equityToken();
        bytes memory tokenInit =
            abi.encodeWithSelector(
                equityToken.initialize.selector,
                address(compliance),
                admin
            );

        token = equityToken(
            address(new ERC1967Proxy(address(tokenImpl), tokenInit))
        );

        /* ---------------- Baseline Compliance ---------------- */

        vm.startPrank(admin);

        registry.approve(admin);
        registry.approve(alice);
        registry.approve(bob);

        registry.removeFromBlackList(admin);
        registry.removeFromBlackList(alice);
        registry.removeFromBlackList(bob);

        vm.stopPrank();

        /* ---------------- Distribute Shares ---------------- */

        vm.prank(admin);
        token.transfer(alice, 10);
    }

   

    function test_transfer_succeeds_when_compliant() public {
        vm.prank(alice);
        token.transfer(bob, 1);

        assertEq(token.balanceOf(bob), 1);
        assertEq(token.balanceOf(alice), 9);
    }
    //======================Pause================================   

    function test_transfer_reverts_when_paused() public {
        vm.prank(admin);
        compliance.pauseTransfers();

        vm.expectRevert(" Tranfer Not Compliant");
        vm.prank(alice);
        token.transfer(bob, 1);
    }

   
     //===========================BLACKLIST=================================
  

    function test_transfer_reverts_when_sender_blacklisted() public {
        vm.prank(admin);
        registry.blackList(alice);

        vm.expectRevert(" Tranfer Not Compliant");
        vm.prank(alice);
        token.transfer(bob, 1);
    }

    function test_transfer_reverts_when_recipient_blacklisted() public {
        vm.prank(admin);
        registry.blackList(bob);

        vm.expectRevert(" Tranfer Not Compliant");
        vm.prank(alice);
        token.transfer(bob, 1);
    }

    
    //=========================APPROVAL===================================
   

    function test_transfer_reverts_when_recipient_not_approved() public {
        vm.prank(admin);
        registry.revoke(bob);

        vm.expectRevert(" Tranfer Not Compliant");
        vm.prank(alice);
        token.transfer(bob, 1);
    }

    
    //=======================LOCKUP=============================================
   

    function test_transfer_reverts_when_sender_locked() public {
        vm.prank(admin);
        compliance.setLockUp(alice, uint64(block.timestamp + 1 days));

        vm.expectRevert(" Tranfer Not Compliant");
        vm.prank(alice);
        token.transfer(bob, 1);
    }

   
     //=================== FORCED TRANSFER=====================================
  

    function test_admin_can_force_transfer() public {
        vm.prank(admin);
        token.forcedTransfer(alice, bob, 1);

        assertEq(token.balanceOf(bob), 1);
    }

    function test_forced_transfer_respects_pause() public {
        vm.prank(admin);
        compliance.pauseTransfers();

        vm.expectRevert(" Tranfer Not Compliant");
        vm.prank(admin);
        token.forcedTransfer(alice, bob, 1);
    }
}
