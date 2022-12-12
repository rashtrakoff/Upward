// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.15;

import "../src/StreamManagerFactory.sol";
import "../src/StreamManager.sol";
import "forge-std/Script.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPK = vm.envUint("PRIVATE_KEY");
        address host = vm.envAddress("SF_HOST_ADDRESS");
        address cfa = vm.envAddress("CFA_ADDRESS");
        address forwarder = vm.envAddress("CFAV1_FORWARDER_ADDRESS");
        vm.startBroadcast(deployerPK);

        // Deploy new stream manager implementation contract.
        address streamManagerImplementation = address(new StreamManager());

        // Deploy factory contract.
        new StreamManagerFactory({
            _host: host,
            _cfa: cfa,
            _cfaV1Forwarder: forwarder,
            _streamManagerImplementation: streamManagerImplementation
        });

        vm.stopBroadcast();
    }
}