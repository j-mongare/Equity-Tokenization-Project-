// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/equityToken.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/*//////////////////////////////////////////////////////////////
                            MOCK
//////////////////////////////////////////////////////////////*/

contract MockCompliance is IComplianceModule {
    bool public allowed;

    constructor(bool _allowed) {
        allowed = _allowed;
    }

    function setAllowed(bool _allowed) external {
        allowed = _allowed;
    }

    function canTransfer(
        address,
        address,
        uint256
    ) external view returns (bool) {
        return allowed;
    }
}

/*//////////////////////////////////////////////////////////////
                          TESTS
//////////////////////////////////////////////////////////////*/

contract EquityTokenTest is Test {
    equityToken token;
    MockCompliance compliance;

    address admin = address(0xA11CE);
    address user1 = address(0xB0B);

    function setUp() public {
        compliance = new MockCompliance(true);

        // Deploy implementation
        equityToken implementation = new equityToken();

        // Encode initializer
        bytes memory data = abi.encodeCall(
            equityToken.initialize,
            (address(compliance), admin)
        );

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            data
        );

        // Use proxy as equityToken
        token = equityToken(address(proxy));
    }

    function testInitialSupplyMintedToAdmin() public {
        assertEq(token.totalSupply(), 1000);
        assertEq(token.balanceOf(admin), 1000);
    }

    function testDecimalsIsZero() public {
        assertEq(token.decimals(), 0);
    }

    function testTransferBlockedByCompliance() public {
        compliance.setAllowed(false);

        vm.prank(admin);
        vm.expectRevert(" Tranfer Not Compliant");
        token.transfer(user1, 10);
    }

    function testForcedTransferWorksForAuthorizedRole() public {
        vm.prank(admin);
        token.forcedTransfer(admin, user1, 100);

        assertEq(token.balanceOf(user1), 100);
        assertEq(token.balanceOf(admin), 900);
    }

    function testForcedTransferRevertsForUnauthorized() public {
        vm.prank(user1);
        vm.expectRevert();
        token.forcedTransfer(admin, user1, 1);
    }
}
