pragma solidity ^0.8.20;

import {OApp, Origin, MessagingFee} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {CrossChainOrder} from "./EIP7683/structs/CrossChainOrder.sol";
import {ResolvedCrossChainOrder, Input, Output} from "./EIP7683/structs/ResolvedCrossChainOrder.sol";
import {ERC20} from "lib/solady/src/tokens/ERC20.sol";

abstract contract Messenger is OApp {
    mapping(bytes32 => bool) public filledOrders;

    /**
     * @notice Sends a message from the source to destination chain.
     * @param _dstEid Destination chain's endpoint ID.
     * @param _payload The message to send.
     * @param _options Message execution options (e.g., for sending gas to destination).
     */
    function send(
        uint32 _dstEid,
        bytes memory _payload,
        bytes calldata _options
    ) external payable {
        _lzSend(
            _dstEid, // Destination chain's endpoint ID.
            _payload, // Encoded message payload being sent.
            _options, // Message execution options (e.g., gas to use on destination).
            MessagingFee(msg.value, 0), // Fee struct containing native gas and ZRO token.
            payable(msg.sender) // The refund address in case the send call reverts.
        );
    }

    /**
     * @dev Called when data is received from the protocol. It overrides the equivalent function in the parent contract.
     * Protocol messages are defined as packets, comprised of the following parameters.
     * @param _origin A struct containing information about where the packet came from.
     * @param _guid A global unique identifier for tracking the packet.
     * @param payload Encoded message.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata payload,
        address, // Executor address as specified by the OApp.
        bytes calldata // Any extra data or options to trigger on receipt.
    ) internal override {
        // receive a message containing an order
        // if the order was filled, then we can resolve it and release the funds

        (bool filled, CrossChainOrder memory order) = abi.decode(
            payload,
            (bool, CrossChainOrder)
        );
        bytes32 orderHash = keccak256(abi.encode(order));

        if (filled) {
            filledOrders[orderHash] = true;
        }
    }
}
