pragma solidity ^0.8.13;

import "../structs/CrossChainOrder.sol";
import "../structs/ResolvedCrossChainOrder.sol";

/// @title ISettlementContract
/// @notice Standard interface for settlement contracts
interface ISettlementContract {
    /// @notice Initiates the settlement of a cross-chain order
    /// @dev To be called by the filler
    /// @param order The CrossChainOrder definition
    /// @param signature The swapper's signature over the order
    /// @param fillerData Any filler-defined data required by the settler
    function initiate(
        CrossChainOrder memory order,
        bytes calldata signature,
        bytes calldata fillerData
    ) external;

    /// @notice Resolves a specific CrossChainOrder into a generic ResolvedCrossChainOrder
    /// @dev Intended to improve standardized integration of various order types and settlement contracts
    /// @param order The CrossChainOrder definition
    /// @param fillerData Any filler-defined data required by the settler
    function resolve(
        CrossChainOrder memory order,
        bytes memory fillerData
    ) external view returns (ResolvedCrossChainOrder memory);
}
