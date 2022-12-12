// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.15;

import "./helpers/Setup.sol";
import "forge-std/console.sol";

contract SetupTest is Test, Setup {

  function testSetUp() public {
    assertTrue(address(Factory) != address(0), "new Factory null");
    assertTrue(streamManagerImplementation != address(0), "new streamManagerImplementation is null");
  }
  // test createSet
  function testCreateStreamManager () public {
    address newStreamManager = _createStreamManager();

    assertTrue(newStreamManager != address(0), "new stream manager is null");
  }
}