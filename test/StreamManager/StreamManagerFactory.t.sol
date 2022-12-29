// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.15;

import "../helpers/Setup.sol";
import "forge-std/console.sol";

contract StreamManagerFactoryTest is Test, Setup {
    function testSetUp() public {
        assertTrue(address(Factory) != address(0), "new Factory null");
        assertTrue(
            streamManagerImplementation != address(0),
            "new streamManagerImplementation is null"
        );
    }

    function testCreateStreamManager() public {
        address newStreamManager = _createStreamManager();

        assertTrue(
            newStreamManager != address(0),
            "new stream manager is null"
        );
        assertTrue(
            keccak256(abi.encode(StreamManager(newStreamManager).name())) ==
                keccak256(abi.encode("TESTING")),
            "Name is wrong"
        );
        assertTrue(
            keccak256(abi.encode(StreamManager(newStreamManager).symbol())) ==
                keccak256(abi.encode("TEST")),
            "Symbol is wrong"
        );
    }
}
