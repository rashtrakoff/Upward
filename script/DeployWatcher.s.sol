// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.15;

import "../src/Watcher/WatcherFactory.sol";
import "../src/Watcher/Watcher.sol";
import "forge-std/Script.sol";

contract DeployWatcherScript is Script {
    function run() external {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        address forwarder = vm.envAddress("CFAV1_FORWARDER_ADDRESS");
        vm.startBroadcast(deployerPK);

        // Deploy new stream manager implementation contract.
        address watcherImplementation = address(new Watcher());

        // Deploy factory contract.
        new WatcherFactory({
            _cfaV1Forwarder: forwarder,
            _watcherImplementation: watcherImplementation
        });

        vm.stopBroadcast();
    }
}