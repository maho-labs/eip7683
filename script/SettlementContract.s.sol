// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SettlementContract} from "../src/SettlementContract.sol";
import "lib/solady/src/utils/CREATE3.sol";

contract SettlementScript is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();

        address mailbox = 0x979Ca5202784112f4738403dBec5D0F3B9daabB9;

        bytes32 salt = "12345";
        bytes memory creationCode = abi.encodePacked(
            type(SettlementContract).creationCode,
            abi.encode(mailbox)
        );

        address computedAddress = CREATE3.deploy(salt, creationCode, 0);
        address deployedAddress = CREATE3.getDeployed(salt);
    }
}
