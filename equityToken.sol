// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

//@title: equityToken, an onchain representation of a company's shares

interface IComplianceModule{
    function canTransfer(address from, address to, uint256 amount) external view returns (bool);
}
contract equityToken is ERC20Upgradeable, AccessControlUpgradeable, UUPSUpgradeable{

    //================Roles=======================
    bytes32 public constant COMPLIANCE_ADMIN_ROLE = keccak256 ("COMPLIANCE_ADMIN_ROLE") ;
    bytes32 public constant FORCED_TRANSFER_ROLE = keccak256("FORCED_TRANSFER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256 ("UPGRADER_ROLE");
    

    //=====================State Variables===================
    IComplianceModule internal complianceModule;
    uint256 public constant TOTAL_SHARES= 1000;

    uint256[49] private __gap;

    //@custom: oz-upgrades-unsafe-allow constructor
    // @notice this permanantly bricks the logic contract
    //@dev this is done to curtail upgrade authority hostile take overs
    constructor(){
        _disableInitializers();
    }
    function initialize ( address compliance, address admin) external initializer{
        __AccessControl_init(); 
        __ERC20_init("equityToken", "EQT");
      //  __UUPSUpgradeable_init(); v5 OZ depracated this initializer
        complianceModule = IComplianceModule(compliance);

        _grantRole (COMPLIANCE_ADMIN_ROLE, admin);
        _grantRole (UPGRADER_ROLE, admin);
        _grantRole(FORCED_TRANSFER_ROLE,admin);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        

          //@notice we skipped compliance checks here, as this is a corporate initiative
        _mint(admin, TOTAL_SHARES);

    }
    // ERC20 HOOKS
    //@notice this ensures transfers do not bypass compliance and 
    // prevents creative transfer paths, as _update() cannot be bypassed

    function _update (address from, address to, uint256 amount) internal override(ERC20Upgradeable){
        if( from != address(0) && to != address(0)){
           require( complianceModule.canTransfer(from, to, amount), " Tranfer Not Compliant");

        }
        super._update(from, to, amount);

    }
    //@notice this role ought to be assigned to:
    // 1. regulators
    //2. court agents
    // 3. trustees
    // 4. company registrar (depending on the jurisdiction of formation)
    function forcedTransfer( address from, address to, uint256 amount)external onlyRole(FORCED_TRANSFER_ROLE){
        require (from != address (0), " Invalid from");
        require (to != address (0), " Invalid to");
        require (amount > 0, " zERO amount");

        // OPtional enforce compliance on recepient (to)
        //require (complianceModule.canTransfer(from, to, amount), " Transef Not Compliant");

        _update(from, to, amount);
        

    }
    function setComplianceModule(address module) external onlyRole(COMPLIANCE_ADMIN_ROLE){
        require (module != address(0), " Invalid address");

        complianceModule = IComplianceModule(module);
    }
    //=================Upgrade logic=========================

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE){}
    
    // 1share = 1 token
     function decimals () public pure override returns(uint8){
        return 0;
     }
     function supportsInterface(bytes4 interfaceId) public view override(AccessControlUpgradeable) returns (bool){
    return super.supportsInterface(interfaceId);
}
    

}
