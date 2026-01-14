// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

 //@title dividendDistributor.sol
 //@notice Upgradeable pull-based dividend distribution (ERC-20 only)

interface IEquityToken{
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);

     // Optional legal action
   // function forcedTransfer(address from, address to, uint256 amount) external;
}
contract DividendDistributor is Initializable, AccessControlUpgradeable{
    using SafeERC20 for IERC20;

    //===================Roles============================
    bytes32 public constant FINANCE_ROLE = keccak256 ("FINANCE_ROLE");

    //===================STORAGE==========================
     IERC20 public equityToken;  // share token
     IERC20 public payoutToken; // dividend token ( eg., USDT or USDC)

     uint256 public totalDividendsDeclared;
     mapping (address => uint256 ) public claimed;


     uint256 [46] private __gap; // STORAGE GAP

     //===================Events==============================

     event DividendsDeposited(uint256 amount);
     event Claimed (address indexed account, uint256 amount);

     //==================Constructor=======================

    // @custom : oz-upgrades-unsafe-allow constructor
    constructor () {_disableInitializers();}

    //===================Initialization============================

    function initialize (address admin, address _equityToken, address _payoutToken) public initializer {

        __AccessControl_init();
         equityToken = IERC20(_equityToken);
         payoutToken = IERC20 (_payoutToken);

         _grantRole (DEFAULT_ADMIN_ROLE, admin);
         _grantRole(FINANCE_ROLE, admin);

    }
    //=================================Funding===========================
    //@notice deposit dividends into the pool
    //@dev pull payout tokens from caller via SafeERC20

    function depositDividends(uint256 amount) external onlyRole (FINANCE_ROLE){
        require (amount > 0, " Zero Amount");

        totalDividendsDeclared += amount;

        payoutToken. safeTransfer (address(this), amount);

        emit DividendsDeposited(amount);

    }
    //=====================Claims=============================
    //@notice claim accrued dividends

    function claim( address account) external {
        require (account != address (0), "Zero Address");
        
        uint256 entitlement = equityToken.balanceOf(account);
        require (entitlement != 0, " No dividends to Pay");

        uint amount = entitlement - claimed[account];
        require (amount !=0, "Nothing to Pay");

        claimed[account] -= amount; // state update b4 transfer

        payoutToken. safeTransfer (account , amount);

        emit Claimed (account, amount);

    }
     //@notice view how much an account can claim
     //@return unclaimed entitlement
    function claimable (address account) external view returns (uint256){
      require (account != address (0), "Zero Address");  

      uint256 unclaimedEntitlement = equityToken.balanceOf(account)- claimed[account];
      return unclaimedEntitlement; 


    }
}
     