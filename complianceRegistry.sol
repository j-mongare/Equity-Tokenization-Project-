// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

//@title complianceRegistry.sol

contract ComplianceRegistry is Initializable, AccessControlUpgradeable{
    //==================Roles==================
    bytes32 public constant COMPLIANCE_ADMIN_ROLE = keccak256("COMPLIANCE_ADMIN_ROLE"); 
   

    //=============sTATE VARIABLES====================
    mapping (address => bool)internal approved;
    mapping (address => bool ) internal  blackListed;
    mapping (address => bytes32) internal jurisdiction;
    mapping (address => bytes32) internal investorClass;

    uint256 [46] private __gap;

    constructor (){
        _disableInitializers();
    }

    function initialize(address admin) public initializer{
        __AccessControl_init();
       

        _grantRole (COMPLIANCE_ADMIN_ROLE, admin); // compliance officers 
        _grantRole(DEFAULT_ADMIN_ROLE, admin); // corporate authority
      

    }
    //=================Required read functions==============================

    function isApproved(address user) external view returns (bool){
        return approved[user];

    }
    function isBlackListed (address user) external view returns (bool){
        return blackListed[user];
    }
    function getJurisdiction (address user) external view returns (bytes32){
        return jurisdiction[user];
    }
     // investorClass => Retai, accredited or institutional

    function getInvestorClass(address user ) external view returns (bytes32){
        return investorClass[user];
    }

    //==================Compliance Admin things==========================
    function approve (address user) external onlyRole(COMPLIANCE_ADMIN_ROLE){
        approved[user] = true;
    }
   //revoke approval

    function revoke (address user ) external onlyRole(COMPLIANCE_ADMIN_ROLE){
        approved [user] = false;
    }
    function blackList (address user ) external onlyRole(COMPLIANCE_ADMIN_ROLE){
        blackListed[user] = true;
    }
     function setJurisdiction (address user , bytes32 country) external onlyRole (COMPLIANCE_ADMIN_ROLE){
        jurisdiction[user] = country;
     }
    

     function setInvestorClass(address user, bytes32 class)external onlyRole (COMPLIANCE_ADMIN_ROLE){
        investorClass[user] = class;
     }
     function removeFromBlackList(address user)external onlyRole (COMPLIANCE_ADMIN_ROLE){
        blackListed[user] = false;
     }


}

