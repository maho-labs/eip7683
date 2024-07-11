pragma solidity ^0.8.20;

struct DestinationAppData {
    address target; // contract I wish to call on the destination chain after my intent is fulfilled
    bytes targetData; // calldata I want to execute on target contract on destination chain
}
