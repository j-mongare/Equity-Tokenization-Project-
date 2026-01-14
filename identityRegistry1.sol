// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

//@title identityRegistry.sol

contract IdentityRegistry is Initializable, AccessControlUpgradeable{

    //==============Roles==================================
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
   

    //=============State Vars=====================================
    mapping (address => bytes32) private identityHash;
    mapping (address => mapping ( bytes32 => bool)) private claims; // wallet => claim => present
    mapping (address => bool)private trustedIssuer;
    // append new state vars here to avoid storage collision 

    uint256[47] private __gap;

    //==================Events============================
    event WalletRegistered (address indexed wallet, bytes32 _identityHash);
    event WalletRemoved (address indexed wallet);
    event ClaimAdded ( address indexed wallet, bytes32 claim);
    event ClaimRemoved(address indexed wallet, bytes32 claim);
    event TrustedIssuerAdded(address indexed issuer);
    event TrustedIssuerRemoved(address indexed issuer);
    event IssuerRoleGranted (address indexed issuer);
    event IssuerRoleRevoked (address indexed issuer);

   //=========================Constructor================================
    //@custom: oz-upgrades-unsafe-allow constructor
    constructor (){
        _disableInitializers();
    }

    //===============Initialization===========================
     //@dev initializes contract with admin address
     //@dev admin is granted issuer and default admin roles
    function initialize (address admin) public initializer {
        __AccessControl_init();
     

        _grantRole (ISSUER_ROLE, admin);
        _grantRole (DEFAULT_ADMIN_ROLE, admin);

        trustedIssuer[admin] = true;
        
    }

    //==========================Identity Management=================================

    //@notice Links a wallet to a legal identity reference
    //Callable only by trusted issuers
    //Overwrites previous identity if re-issued
    function registerIdentity(address wallet, bytes32 _newIdentityHash ) external onlyRole(ISSUER_ROLE){
        require (wallet != address (0), " Zero Address ");
        require (_newIdentityHash != bytes32(0), " Zero Hash");

        identityHash[wallet] = _newIdentityHash;

        emit WalletRegistered ( wallet, _newIdentityHash);

    }
    //@ notice Used for revocation, errors, or legal orders
    function removeIdentity (address wallet) external onlyRole(ISSUER_ROLE){
        delete identityHash[wallet];

        emit WalletRemoved(wallet);
    }
     //@ notice returns whether a wallet has a registered identity
    function hasIdentity (address wallet) internal view returns (bool){
       return  identityHash[wallet] != bytes32(0);
    }
      //@notice returns the identity hash associated with a particular wallet
    function getIdentity (address wallet) external view returns (bytes32){

        return identityHash[wallet];

    }

    //==================Claims Management===================================

    //@dev claims represent facts, not permissions. Eg., accredited investor, Identity verified, etc

    function addClaim (address wallet, bytes32 _claim ) external onlyRole (ISSUER_ROLE){
        require (identityHash[wallet] != bytes32(0), " No identity");

       claims[wallet][_claim] = true;
      

       emit ClaimAdded (wallet, _claim);

    }

    function removeClaim (address wallet, bytes32 claim) internal onlyRole (ISSUER_ROLE){
         require (identityHash[wallet] != bytes32(0), " No identity"); 

        claims [wallet][claim] = false;

        emit ClaimRemoved (wallet, claim);

    }
    function hasClaim (address wallet, bytes32 _claim) internal view returns (bool){

        return claims[wallet][_claim];


    }
    //=====================Trusted Issuer Management=============================

    //@notice trusted issuers who can attest claims and identities of users

    function addTrustedIssuer(address issuer) internal onlyRole (DEFAULT_ADMIN_ROLE){
      
        
        trustedIssuer[issuer] = true;

        emit TrustedIssuerAdded (issuer);
    }
    function removeTrustedIssuer(address issuer)internal onlyRole (DEFAULT_ADMIN_ROLE){
        trustedIssuer[issuer] = false;
    }
    function isTrustedIssuer(address issuer) internal view returns (bool){
       return trustedIssuer[issuer];
    }

    
   


}