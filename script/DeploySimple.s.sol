// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.15;

import "../src/SimpleStreamManagerFactory.sol";
import "../src/SimpleStreamManager.sol";
import "forge-std/Script.sol";

contract DeploySimpleScript is Script {
    function run() external {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        address forwarder = vm.envAddress("CFAV1_FORWARDER_ADDRESS");
        vm.startBroadcast(deployerPK);

        // Deploy new stream manager implementation contract.
        address streamManagerImplementation = address(new SimpleStreamManager());

        // Deploy factory contract.
        new SimpleStreamManagerFactory({
            _cfaV1Forwarder: forwarder,
            _streamManagerImplementation: streamManagerImplementation
        });

        vm.stopBroadcast();
    }
}