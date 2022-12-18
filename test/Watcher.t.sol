// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.15;

import "./helpers/WatcherSetup.sol";
import "forge-std/console.sol";

contract WatcherTest is Test, Setup {
    using CFAv1Library for CFAv1Library.InitData;

    function testAfterAgreementCreatedSingle() public {
        address watcher = _createWatcher();
        CFAv1Forwarder forwarder = sf.cfaV1Forwarder;
        CFAv1Library.InitData storage cfaLib = sf.cfaLib;
        int96 incomingFlowrate = _convertToRate(1e10);

        vm.prank(alice);
        cfaLib.createFlow(
            admin,
            ISuperToken(address(superToken)),
            incomingFlowrate
        );

        assertEq(
            forwarder.getFlowrate(superToken, alice, admin),
            incomingFlowrate,
            "Subscriber's payment rate is incorrect"
        );
        assertEq(
            Watcher(watcher).balanceOf(alice),
            1,
            "Wrong balance by watcher"
        );
    }

    function testAfterAgreementTerminatedSingle() public {
        address watcher = _createWatcher();
        CFAv1Forwarder forwarder = sf.cfaV1Forwarder;
        CFAv1Library.InitData storage cfaLib = sf.cfaLib;

        vm.startPrank(alice);
        cfaLib.createFlow(
            admin,
            ISuperToken(address(superToken)),
            _convertToRate(1e10)
        );
        cfaLib.deleteFlow(
            alice,
            admin,
            ISuperToken(address(superToken))
        );
        vm.stopPrank();

        assertEq(
            forwarder.getFlowrate(superToken, alice, admin),
            0,
            "Subscriber's payment rate is incorrect"
        );
        assertEq(
            Watcher(watcher).balanceOf(alice),
            0,
            "Wrong balance by watcher"
        );
    }
}
