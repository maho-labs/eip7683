pragma solidity ^0.8.13;

/// @title ResolvedCrossChainOrder type
/// @notice An implementation-generic representation of an order
/// @dev Defines all requirements for filling an order by unbundling the implementation-specific orderData.
/// @dev Intended to improve integration generalization by allowing fillers to compute the exact input and output information of any order
struct ResolvedCrossChainOrder {
    /// @dev The inputs to be taken from the swapper as part of order initiation
    Input[] swapperInputs;
    /// @dev The outputs to be given to the swapper as part of order fulfillment
    Output[] swapperOutputs;
    /// @dev The outputs to be given to the filler as part of order settlement
    Output[] fillerOutputs;
}

/// @notice Tokens sent by the swapper as inputs to the order
struct Input {
    /// @dev The address of the ERC20 token on the origin chain
    address token;
    /// @dev The amount of the token to be sent
    uint256 amount;
}

/// @notice Tokens that must be receive for a valid order fulfillment
struct Output {
    /// @dev The address of the ERC20 token on the destination chain
    /// @dev address(0) used as a sentinel for the native token
    address token;
    /// @dev The amount of the token to be sent
    uint256 amount;
    /// @dev The address to receive the output tokens
    address recipient;
    /// @dev The destination chain for this output
    uint32 chainId;
}
