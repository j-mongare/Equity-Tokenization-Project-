// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title EquityTokenProxy
/// @notice Thin, named proxy for the EquityToken (UUPS-compatible)
/// @dev Holds ALL state. Logic lives in the implementation.

contract EquityTokenProxy is ERC1967Proxy {

    /// @param implementation Address of the equityToken.sol implementation
    /// @param initData Encoded initialize(...) calldata
    constructor(
        address implementation,
        bytes memory initData
    )
        ERC1967Proxy(implementation, initData)
    {}
}
