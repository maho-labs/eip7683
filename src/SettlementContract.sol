pragma solidity ^0.8.20;

import {OApp, Origin, MessagingFee} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {CrossChainOrder} from "./EIP7683/structs/CrossChainOrder.sol";
import {ResolvedCrossChainOrder, Input, Output} from "./EIP7683/structs/ResolvedCrossChainOrder.sol";
import {DestinationAppData} from "./EIP7683/structs/DestinationAppData.sol";
import {SolutionSegment} from "./EIP7683/structs/SolutionSegment.sol";
import {ERC20} from "lib/solady/src/tokens/ERC20.sol";
import {Messenger} from "./Messenger.sol";
import {EIP7683} from "./EIP7683/EIP7683.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {FailedIntent} from "./EIP7683/errors/Intent.sol";

contract SettlementContract is Messenger, EIP7683 {
    constructor(
        address _endpoint,
        address _owner
    ) OApp(_endpoint, _owner) Ownable(_owner) {}

    /// @notice Resolves a specific CrossChainOrder into a generic ResolvedCrossChainOrder
    /// @dev Intended to improve standardized integration of various order types and settlement contracts
    /// @param order The CrossChainOrder definition
    /// @param fillerData Any filler-defined data required by the settler
    function fill(
        CrossChainOrder memory order,
        bytes memory fillerData
    ) external returns (ResolvedCrossChainOrder memory) {
        (
            DestinationAppData memory appData,
            ResolvedCrossChainOrder memory crossChainOrder
        ) = abi.decode(
                order.orderData,
                (DestinationAppData, ResolvedCrossChainOrder)
            );
        // get hash of cross chain order

        (SolutionSegment[] memory segments, bytes memory _options) = abi.decode(
            fillerData,
            (SolutionSegment[], bytes)
        );

        for (uint256 i = 0; i < segments.length; i++) {
            SolutionSegment memory segment = segments[i];

            (bool success, bytes memory data) = payable(segment.to).call{
                value: segment.value
            }(segment.data);

            if (!success) {
                revert FailedIntent(data);
            }
        }

        _validateSolution(crossChainOrder.swapperOutputs);

        // send message back to origin chain
        bytes memory _payload = abi.encode(true, order); // true represents a non filled order
        this.send(order.originChainId, _payload, _options);
    }

    function _validateSolution(Output[] memory outputs) private view {
        for (uint256 i = 0; i < outputs.length; i++) {
            ERC20 token = ERC20(outputs[i].token);

            uint256 balance = token.balanceOf(outputs[i].recipient);
            require(balance >= outputs[i].amount);
        }
    }

    function claim(CrossChainOrder memory order) public {
        bytes32 orderHash = keccak256(abi.encode(order));

        require(filledOrders[orderHash], "Order not filled");

        (
            DestinationAppData memory appData,
            ResolvedCrossChainOrder memory crossChainOrder
        ) = abi.decode(
                order.orderData,
                (DestinationAppData, ResolvedCrossChainOrder)
            );

        for (uint256 i = 0; i < crossChainOrder.fillerOutputs.length; i++) {
            Output memory output = crossChainOrder.fillerOutputs[i];

            ERC20 token = ERC20(output.token);
            token.transfer(output.recipient, output.amount);
        }

        delete filledOrders[orderHash];
    }
}
