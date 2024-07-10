// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./EIP7683/structs/CrossChainOrder.sol";
import "./EIP7683/structs/ResolvedCrossChainOrder.sol";
import "./EIP7683/structs/SolutionSegment.sol";
import "lib/solady/src/tokens/ERC20.sol";
import "./Messenger.sol";

contract SettlementContract is Messenger {
    constructor(
        address _endpoint,
        address _owner
    ) OApp(_endpoint, _owner) Ownable(_owner) {}

    /// @notice Initiates the settlement of a cross-chain order
    /// @dev To be called by the filler
    /// @param order The CrossChainOrder definition
    /// @param signature The swapper's signature over the order
    /// @param fillerData Any filler-defined data required by the settler
    function initiate(
        CrossChainOrder memory order,
        bytes calldata signature,
        bytes calldata fillerData
    ) external {
        bytes32 orderHash = keccak256(abi.encode(order));
        require(!orders[orderHash]);

        (Input[] memory inputs, Output[] memory outputs) = abi.decode(
            order.orderData,
            (Input[], Output[])
        );

        for (uint256 i = 0; i < inputs.length; i++) {
            ERC20 token = ERC20(inputs[i].token);
            token.transferFrom(order.swapper, address(this), inputs[i].amount);
        }

        bytes memory _payload = abi.encode(false, order); // false represents a non filled order
        orders[orderHash] = true;

        (SolutionSegment[] memory segments, bytes memory _options) = abi.decode(
            fillerData,
            (SolutionSegment[], bytes)
        );

        // send the order to the destination chain
        this.send(outputs[0].chainId, _payload, _options);
    }

    /// @notice Resolves a specific CrossChainOrder into a generic ResolvedCrossChainOrder
    /// @dev Intended to improve standardized integration of various order types and settlement contracts
    /// @param order The CrossChainOrder definition
    /// @param fillerData Any filler-defined data required by the settler
    function resolve(
        CrossChainOrder memory order,
        bytes memory fillerData
    ) external returns (ResolvedCrossChainOrder memory) {
        (Input[] memory inputs, Output[] memory outputs) = abi.decode(
            order.orderData,
            (Input[], Output[])
        );

        // get hash of cross chain order

        bytes32 orderHash = keccak256(abi.encode(order));
        require(orders[orderHash]);

        (SolutionSegment[] memory segments, bytes memory _options) = abi.decode(
            fillerData,
            (SolutionSegment[], bytes)
        );

        for (uint256 i = 0; i < segments.length; i++) {
            SolutionSegment memory segment = segments[i];

            payable(segment.to).call{value: segment.value}(segment.data);
        }

        // check erc20 balances for each input
        for (uint256 i = 0; i < inputs.length; i++) {
            ERC20 token = ERC20(inputs[i].token);

            uint256 balance = token.balanceOf(outputs[i].recipient);
            require(balance >= outputs[i].amount);
        }

        // send message back to origin chain
        bytes memory _payload = abi.encode(true, order); // true represents a non filled order
        this.send(order.originChainId, _payload, _options);
    }
}
