// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "./structs/CrossChainOrder.sol";
import "./structs/ResolvedCrossChainOrder.sol";
import "./structs/DestinationAppData.sol";
import "./structs/SolutionSegment.sol";
import "./interfaces/ISettlementContract.sol";
import "lib/solady/src/tokens/ERC20.sol";

abstract contract EIP7683 is ISettlementContract {
    /// @notice Initiates the settlement of a cross-chain order
    /// @dev To be called by the filler
    /// @dev Transfers the swapper's input tokens to the contract, later to be claimed by the solver
    /// @param order The CrossChainOrder definition
    /// @param signature The swapper's signature over the order
    /// @param fillerData Any filler-defined data required by the settler
    function initiate(
        CrossChainOrder memory order,
        bytes calldata signature,
        bytes calldata fillerData
    ) external {
        (
            DestinationAppData memory appData,
            ResolvedCrossChainOrder memory crossChainOrder
        ) = abi.decode(
                order.orderData,
                (DestinationAppData, ResolvedCrossChainOrder)
            );

        for (uint256 i = 0; i < crossChainOrder.swapperInputs.length; i++) {
            ERC20 token = ERC20(crossChainOrder.swapperInputs[i].token);
            token.transferFrom(
                order.swapper,
                address(this),
                crossChainOrder.swapperInputs[i].amount
            );
        }
    }

    /// @notice Resolves a specific CrossChainOrder into a generic ResolvedCrossChainOrder
    /// @dev Intended to improve standardized integration of various order types and settlement contracts
    /// @param order The CrossChainOrder definition
    /// @param fillerData Any filler-defined data required by the settler
    function resolve(
        CrossChainOrder memory order,
        bytes memory fillerData
    ) external view returns (ResolvedCrossChainOrder memory) {
        (
            DestinationAppData memory appData,
            ResolvedCrossChainOrder memory crossChainOrder
        ) = abi.decode(
                order.orderData,
                (DestinationAppData, ResolvedCrossChainOrder)
            );

        return crossChainOrder;
    }
}
