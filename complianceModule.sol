
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// @title complianceModule.sol

interface IComplianceRegistry{
    function isApproved (address user) external view returns (bool);
    function isBlackListed (address user) external view returns (bool);
    function getInvestorClass(address user) external view returns ( bytes32);
}
contract ComplianceModule is Initializable, AccessControlUpgradeable {

    //===============Roles============================
    bytes32 public constant RULES_ADMIN_ROLE = keccak256 ("RULES_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256 ("PAUSER_ROLE");

    //======================sTATE Variables==================
    IComplianceRegistry public complianceRegistry;
    bool internal transferPaused;

    //investorClass => max shares per transfer (simplified) 
    mapping (bytes32 => uint256 ) internal holdingLimit;
    //wallet => lockup expiry
    mapping ( address => uint64) internal lockUpExpiry;

    uint256 [46] private __gap;

 //@custom: oz-upgrades-unsafe-allow constructor
    constructor () {
        _disableInitializers();
    }

    //=================init======================

    function initialize (address admin, address _registry) external initializer{
        __AccessControl_init ();
      complianceRegistry=    IComplianceRegistry(_registry) ;

        _grantRole (RULES_ADMIN_ROLE, admin);
        _grantRole (PAUSER_ROLE, admin);
        _grantRole (DEFAULT_ADMIN_ROLE, admin);

    }
    //====================Core Compliance============================

    function canTransfer ( address from, address to, uint256 amount) external view returns (bool) {
        // sanity check
         if (from == address (0) && to == address (0)) return false;
         if (amount == 0) return false; 
         if(transferPaused) return false; 
         
          // check blacklist
         if ( complianceRegistry.isBlackListed (from) || complianceRegistry.isBlackListed(to)) return false;
         // check for approval
         if (!complianceRegistry.isApproved(to)) return false;

         // lock up period 
         if (block.timestamp < lockUpExpiry[from] ) return false;

         // holding limit 

         bytes32 classTo = complianceRegistry. getInvestorClass(to);
         uint256 limit = holdingLimit[classTo];

         //@ notice limit > 0 ( means a limit is configured)
         // limit == 0 , means no limit has been configured 
         // 0 is used as a sentinel value

         if (limit > 0 && amount > limit) return false; // if a limit exists and amount exceeds it, reject!



         return true;
    }
    // ==============================Admin ===================================
    function pauseTransfers () external onlyRole (PAUSER_ROLE){
        transferPaused = true;
    }
    function unpauseTransfers() external onlyRole (PAUSER_ROLE){
        transferPaused = false;
    }
    function setHoldingLimit(bytes32 investorClass, uint256 limit) external onlyRole (RULES_ADMIN_ROLE){
        holdingLimit [investorClass] = limit;

    }
    function setLockUp(address investor, uint64 expiry)external onlyRole (RULES_ADMIN_ROLE){
        lockUpExpiry[investor] = expiry;
    }
    
}