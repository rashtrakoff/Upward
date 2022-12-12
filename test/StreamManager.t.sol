// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.15;

import "./helpers/Setup.sol";
import "forge-std/console.sol";

contract StreamManagerTest is Test, Setup {
    using CFAv1Library for CFAv1Library.InitData;

    function testAfterAgreementCreatedSingle() public {
        address streamManager = _createStreamManager();
        CFAv1Forwarder forwarder = sf.cfaV1Forwarder;
        CFAv1Library.InitData storage cfaLib = sf.cfaLib;
        int96 incomingFlowrate = _convertToRate(1e10);

        vm.prank(alice);
        cfaLib.createFlow(
            streamManager,
            ISuperToken(address(superToken)),
            incomingFlowrate
        );

        assertEq(
            forwarder.getFlowrate(superToken, alice, streamManager),
            incomingFlowrate,
            "Subscriber's payment rate is incorrect"
        );

        assertEq(
            forwarder.getFlowrate(superToken, streamManager, admin),
            incomingFlowrate,
            "Creator's incoming rate is incorrect"
        );
    }

    function testAfterAgreementTerminatedSingle() public {
        address streamManager = _createStreamManager();
        CFAv1Forwarder forwarder = sf.cfaV1Forwarder;
        CFAv1Library.InitData storage cfaLib = sf.cfaLib;

        vm.startPrank(alice);
        cfaLib.createFlow(
            streamManager,
            ISuperToken(address(superToken)),
            _convertToRate(1e10)
        );
        cfaLib.deleteFlow(
            alice,
            streamManager,
            ISuperToken(address(superToken))
        );
        vm.stopPrank();

        assertEq(
            forwarder.getFlowrate(superToken, alice, streamManager),
            0,
            "Subscriber's payment rate is incorrect"
        );

        assertEq(
            forwarder.getFlowrate(superToken, streamManager, admin),
            0,
            "Creator's flow exists"
        );
    }

    function testAfterAgreementCreatedBulk() public {
        address streamManager = _createStreamManager();
        CFAv1Forwarder forwarder = sf.cfaV1Forwarder;
        CFAv1Library.InitData storage cfaLib = sf.cfaLib;
        int96 incomingFlowrate = _convertToRate(1e10);

        vm.prank(alice);
        cfaLib.createFlow(
            streamManager,
            ISuperToken(address(superToken)),
            incomingFlowrate
        );

        vm.prank(bob);
        cfaLib.createFlow(
            streamManager,
            ISuperToken(address(superToken)),
            incomingFlowrate
        );

        assertEq(
            forwarder.getFlowrate(superToken, alice, streamManager),
            incomingFlowrate,
            "Alice's payment rate is incorrect"
        );
        assertEq(
            forwarder.getFlowrate(superToken, bob, streamManager),
            incomingFlowrate,
            "Bob's payment rate is incorrect"
        );

        assertEq(
            forwarder.getFlowrate(superToken, streamManager, admin),
            2 * incomingFlowrate,
            "Creator's incoming rate is incorrect"
        );
        assertEq(
            forwarder.getAccountFlowrate(superToken, streamManager),
            0,
            "Creator's incoming rate is incorrect"
        );
    }

    function testAfterAgreementTerminatedBulk() public {
        address streamManager = _createStreamManager();
        CFAv1Forwarder forwarder = sf.cfaV1Forwarder;
        CFAv1Library.InitData storage cfaLib = sf.cfaLib;
        int96 incomingFlowrate = _convertToRate(1e10);

        vm.startPrank(alice);
        cfaLib.createFlow(
            streamManager,
            ISuperToken(address(superToken)),
            incomingFlowrate
        );
        cfaLib.deleteFlow(
            alice,
            streamManager,
            ISuperToken(address(superToken))
        );
        vm.stopPrank();

        vm.startPrank(bob);
        cfaLib.createFlow(
            streamManager,
            ISuperToken(address(superToken)),
            incomingFlowrate
        );
        cfaLib.deleteFlow(bob, streamManager, ISuperToken(address(superToken)));
        vm.stopPrank();

        assertEq(
            forwarder.getFlowrate(superToken, alice, streamManager),
            0,
            "Alice's payment rate is incorrect"
        );
        assertEq(
            forwarder.getFlowrate(superToken, bob, streamManager),
            0,
            "Bob's payment rate is incorrect"
        );

        assertEq(
            forwarder.getFlowrate(superToken, streamManager, admin),
            0,
            "Creator's incoming rate is incorrect"
        );
        assertEq(
            forwarder.getAccountFlowrate(superToken, streamManager),
            0,
            "Creator's incoming rate is incorrect"
        );
    }

    function testAfterAgreementUpdated() public {
        address streamManager = _createStreamManager();
        CFAv1Library.InitData storage cfaLib = sf.cfaLib;
        int96 incomingFlowrate = _convertToRate(1e10);

        vm.startPrank(alice);
        cfaLib.createFlow(
            streamManager,
            ISuperToken(address(superToken)),
            incomingFlowrate
        );

        vm.expectRevert(StreamManager.UpdatesNotPermitted.selector);
        cfaLib.updateFlow(
            streamManager,
            ISuperToken(address(superToken)),
            incomingFlowrate / 2
        );
    }
}
