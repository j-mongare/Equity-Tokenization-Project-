# Equity-Tokenization-Project-
This repository contains a modular, upgradeable smart contract system for tokenizing company equity on Ethereum using Solidity and OpenZeppelin upgradeable contracts (v5).  The system separates identity, compliance, governance, equity issuance, and financial distribution concerns to support regulated, long-lived equity instruments.


Architecture Overview
The system is composed of upgradeable implementation contracts deployed behind standard ERC1967 proxies (UUPS pattern). All persistent state lives in the proxy.
Core design principles:
•	Explicit separation of concerns
•	Upgrade safety via UUPS (ERC-1822)
•	Role-based authority using AccessControl
•	No hidden governance logic
•	Minimal inter-contract coupling via interfaces
________________________________________
Contracts
1. EquityToken (equityToken.sol)
On-chain representation of company shares.
Responsibilities:
•	ERC-20 compatible share token (1 token = 1 share, no decimals)
•	Enforces transfer compliance via an external ComplianceModule
•	Supports forced transfers by authorized entities (e.g. courts, regulators)
•	Upgradeable via UUPS
Key features:
•	Overrides _update() to enforce compliance on all transfers
•	Uses AccessControl for governance
•	All shares minted once during initialization
________________________________________
2. ComplianceModule (ComplianceModule.sol)
Rule engine that determines whether a transfer is legally allowed.
Responsibilities:
•	Evaluates transfer legality based on external facts
•	Applies rules such as pauses, lockups, and holding limits
•	Returns a boolean decision to the EquityToken
Notes:
•	Does not store identity data
•	Does not hold balances
•	Designed to be replaceable as regulations evolve
________________________________________
3. ComplianceRegistry (ComplianceRegistry.sol)
Stores compliance-related facts about addresses.
Responsibilities:
•	Tracks approval status and blacklist status
•	Stores jurisdiction and investor classification
•	Exposes read-only functions for compliance checks
Notes:
•	Stores facts only, no business logic
•	Queried by ComplianceModule
•	Upgrade-safe storage layout
________________________________________
4. IdentityRegistry (IdentityRegistry.sol)
Stores identity attestations and claims for wallets.
Responsibilities:
•	Links wallets to off-chain identity references
•	Tracks boolean claims (e.g. KYC verified, accredited investor)
•	Manages authorized issuers via roles
Notes:
•	Uses AccessControl as the sole authority model
•	No transfer or compliance logic
•	No enumeration of claims on-chain
________________________________________
5. DividendDistributor (DividendDistributor.sol)
Pull-based dividend distribution contract.
Responsibilities:
•	Accepts ERC-20 dividend deposits
•	Tracks cumulative entitlements
•	Allows shareholders to claim dividends individually
Design constraints:
•	Pull payments only
•	No loops
•	SafeERC20 usage
•	ERC-20 payouts only (no ETH initially)
________________________________________
6. UpgradeAuthority (UpgradeAuthority.sol)
Governance contract that coordinates upgrades.
Responsibilities:
•	Schedules and executes upgrades for UUPS proxies
•	Enforces optional timelocks
•	Can freeze or unfreeze upgrades per proxy
Notes:
•	Does not hold user state
•	Does not act as a proxy
•	Intended to be owned by a multisig or DAO
________________________________________
7. Proxy (EquityTokenProxy.sol)
Thin wrapper around OpenZeppelin’s ERC1967Proxy.
Responsibilities:
•	Holds all persistent state
•	Delegates calls to the EquityToken implementation
•	Enables UUPS upgrades
Notes:
•	Users interact with the proxy address only
•	Implementation contracts are never used directly
________________________________________
Interfaces
Located in the interfaces/ directory.
•	IEquityToken – minimal interface for balance and supply reads
•	ICompliance – interface for transfer legality checks
•	IIdentity – interface for identity and claim verification
Interfaces are used to:
•	Reduce coupling
•	Make upgrades survivable
•	Avoid importing concrete implementations
________________________________________
Deployment Model
1.	Deploy implementation contracts
2.	Deploy ERC1967 proxies pointing to implementations
3.	Initialize via proxy using encoded calldata
4.	Interact exclusively with proxy addresses
5.	Perform upgrades via UpgradeAuthority
________________________________________
Upgrade Model
•	UUPS (ERC-1822)
•	_authorizeUpgrade() implemented in upgradeable contracts
•	UpgradeAuthority coordinates upgrade execution
•	Storage gaps reserved in all upgradeable contracts

**Testing Strategy

This project uses layered testing to validate behavior at different depths:

Unit / Component Tests
Focus on individual contracts or subsystems in isolation.
Some dependencies may be mocked to verify local logic.

Integration Tests (*.Integration.t.sol)
Test how multiple real contracts interact, with mocks allowed at system boundaries.
Used to verify that equityToken correctly enforces decisions returned by the compliance layer.

System Tests (*.System.t.sol)
Full end-to-end tests using only real production contracts and proxies.
No mocks. These tests validate the system exactly as deployed.

________________________________________
Notes
This system is intentionally modular and conservative.
Identity, compliance, and governance logic are isolated to minimize legal and technical risk during upgrades.
________________________________________
Disclaimer
This codebase is provided for educational and architectural purposes.
It is not legal advice and has not been audited for production use.

