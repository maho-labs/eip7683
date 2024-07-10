pragma solidity ^0.8.13;

/// @title CrossChainOrder type
/// @notice Standard order struct to be signed by swappers, disseminated to fillers, and submitted to settlement contracts
struct CrossChainOrder {
    /// @dev The contract address that the order is meant to be settled by.
    /// Fillers send this order to this contract address on the origin chain
    address settlementContract;
    /// @dev The address of the user who is initiating the swap,
    /// whose input tokens will be taken and escrowed
    address swapper;
    /// @dev Nonce to be used as replay protection for the order
    uint256 nonce;
    /// @dev The chainId of the origin chain
    uint32 originChainId;
    /// @dev The timestamp by which the order must be initiated
    uint32 initiateDeadline;
    /// @dev The timestamp by which the order must be filled on the destination chain
    uint32 fillDeadline;
    /// @dev Arbitrary implementation-specific data
    /// Can be used to define tokens, amounts, destination chains, fees, settlement parameters,
    /// or any other order-type specific information
    bytes orderData;
}
