pragma solidity ^0.8.20;

import {CrossChainOrder} from "./EIP7683/structs/CrossChainOrder.sol";
import {ResolvedCrossChainOrder, Input, Output} from "./EIP7683/structs/ResolvedCrossChainOrder.sol";
import {DestinationAppData} from "./EIP7683/structs/DestinationAppData.sol";
import {SolutionSegment} from "./EIP7683/structs/SolutionSegment.sol";
import {ERC20} from "lib/solady/src/tokens/ERC20.sol";
import {EIP7683} from "./EIP7683/EIP7683.sol";
import {FailedIntent} from "./EIP7683/errors/Intent.sol";
import "@hyperlane-xyz/core/interfaces/IMailbox.sol";

contract SettlementContract is EIP7683 {
    IMailbox public mailbox;
    mapping(bytes32 => bool) public filledOrders;

    constructor(address _mailbox) {
        mailbox = IMailbox(_mailbox);
    }

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

        Input[] memory state = _snapshotCurrentState(
            crossChainOrder.swapperOutputs
        );

        (SolutionSegment[] memory segments, address destination) = abi.decode(
            fillerData,
            (SolutionSegment[], address)
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

        _validateSolution(state, crossChainOrder.swapperOutputs);

        // send message back to origin chain
        bytes32 _hash = keccak256(abi.encode(order)); // true represents a non filled order

        mailbox.dispatch(
            order.originChainId,
            _addressToBytes32(destination),
            abi.encode(_hash)
        );
    }

    function _snapshotCurrentState(
        Output[] memory outputs
    ) internal view returns (Input[] memory state) {
        for (uint256 i = 0; i < outputs.length; i++) {
            ERC20 token = ERC20(outputs[i].token);

            uint256 balance = token.balanceOf(outputs[i].recipient);
            state[i] = Input(outputs[i].token, balance);
        }
    }

    function _validateSolution(
        Input[] memory state,
        Output[] memory outputs
    ) internal view {
        for (uint256 i = 0; i < outputs.length; i++) {
            ERC20 token = ERC20(outputs[i].token);

            uint256 diff = token.balanceOf(outputs[i].recipient) -
                state[i].amount;
            require(diff >= outputs[i].amount);
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

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _data
    ) external payable {
        bytes32 _hash = abi.decode(_data, (bytes32));
        filledOrders[_hash] = true;
    }

    function _addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }
}
