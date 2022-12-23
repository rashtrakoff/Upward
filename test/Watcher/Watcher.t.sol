// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.15;

import "../helpers/WatcherSetup.sol";
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

    function testAfterAgreementCreatedBulk() public {
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
        vm.prank(bob);
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
            forwarder.getFlowrate(superToken, bob, admin),
            incomingFlowrate,
            "Subscriber's payment rate is incorrect"
        );
        assertEq(
            Watcher(watcher).balanceOf(alice),
            1,
            "Wrong balance by watcher"
        );
        assertEq(
            Watcher(watcher).balanceOf(bob),
            1,
            "Wrong balance by watcher"
        );
    }

    function testAfterAgreementUpdated() public {
        address watcher = _createWatcher();
        CFAv1Forwarder forwarder = sf.cfaV1Forwarder;
        CFAv1Library.InitData storage cfaLib = sf.cfaLib;

        vm.startPrank(alice);
        cfaLib.createFlow(
            admin,
            ISuperToken(address(superToken)),
            _convertToRate(1e10)
        );

        // Skipping 1 hour ahead.
        skip(3600);

        cfaLib.updateFlow(
            admin,
            ISuperToken(address(superToken)),
            _convertToRate(1e8)
        );

        assertEq(
            forwarder.getFlowrate(superToken, alice, admin),
            _convertToRate(1e8),
            "Subscriber's payment rate is incorrect"
        );
        assertEq(
            Watcher(watcher).balanceOf(alice),
            0,
            "Wrong balance by watcher"
        );

        skip(3600);

        cfaLib.updateFlow(
            admin,
            ISuperToken(address(superToken)),
            _convertToRate(1e12)
        );

        assertEq(
            forwarder.getFlowrate(superToken, alice, admin),
            _convertToRate(1e12),
            "Subscriber's payment rate is incorrect"
        );
        assertEq(
            Watcher(watcher).balanceOf(alice),
            1,
            "Wrong balance by watcher"
        );

        vm.stopPrank();
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
        cfaLib.deleteFlow(alice, admin, ISuperToken(address(superToken)));
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

    function testAfterAgreementTerminatedBulk() public {
        address watcher = _createWatcher();
        CFAv1Forwarder forwarder = sf.cfaV1Forwarder;
        CFAv1Library.InitData storage cfaLib = sf.cfaLib;

        vm.startPrank(alice);
        cfaLib.createFlow(
            admin,
            ISuperToken(address(superToken)),
            _convertToRate(1e10)
        );
        cfaLib.deleteFlow(alice, admin, ISuperToken(address(superToken)));
        vm.stopPrank();
        vm.startPrank(bob);
        cfaLib.createFlow(
            admin,
            ISuperToken(address(superToken)),
            _convertToRate(1e10)
        );
        cfaLib.deleteFlow(bob, admin, ISuperToken(address(superToken)));
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
        assertEq(
            forwarder.getFlowrate(superToken, bob, admin),
            0,
            "Subscriber's payment rate is incorrect"
        );
        assertEq(
            Watcher(watcher).balanceOf(bob),
            0,
            "Wrong balance by watcher"
        );
    }

    function testSetPaymentToken() public {
        address watcher = _createWatcher();
        CFAv1Forwarder forwarder = sf.cfaV1Forwarder;
        CFAv1Library.InitData storage cfaLib = sf.cfaLib;

        vm.startPrank(admin);
        (, SuperToken newSuperToken) = createNewTokenPair("Test token", "TEST");

        Watcher(watcher).setPaymentToken(address(newSuperToken));

        assertEq(
            address(Watcher(watcher).paymentToken()),
            address(newSuperToken),
            "New supertoken address is wrong"
        );

        vm.stopPrank();
    }

    function testSetPaymentFlowrate() public {
        address watcher = _createWatcher();

        vm.startPrank(admin);

        Watcher(watcher).setPaymentFlowrate(_convertToRate(1e11));

        assertEq(
            Watcher(watcher).paymentFlowrate(),
            _convertToRate(1e11),
            "Payment flowrates don't match"
        );

        vm.stopPrank();
    }

    function testAccessAfterPaymentFlowrateChange() public {
        address watcher = _createWatcher();
        int96 incomingFlowrate = _convertToRate(1e10);
        CFAv1Library.InitData storage cfaLib = sf.cfaLib;

        vm.prank(alice);
        cfaLib.createFlow(
            admin,
            ISuperToken(address(superToken)),
            incomingFlowrate
        );

        assertEq(
            Watcher(watcher).balanceOf(alice),
            1,
            "Wrong balance by watcher"
        );

        vm.startPrank(admin);

        Watcher(watcher).setPaymentFlowrate(_convertToRate(1e11));

        assertEq(
            Watcher(watcher).paymentFlowrate(),
            _convertToRate(1e11),
            "Payment flowrates don't match"
        );

        assertEq(
            Watcher(watcher).balanceOf(alice),
            0,
            "Wrong balance by watcher after payment flowrate change"
        );

        Watcher(watcher).setPaymentFlowrate(_convertToRate(1e8));

        assertEq(
            Watcher(watcher).balanceOf(alice),
            1,
            "Wrong balance by watcher after payment flowrate change"
        );

        vm.stopPrank();
    }

    function testAccessAfterPaymentTokenChange() public {
        address watcher = _createWatcher();
        int96 incomingFlowrate = _convertToRate(1e10);
        CFAv1Library.InitData storage cfaLib = sf.cfaLib;

        vm.prank(alice);
        cfaLib.createFlow(
            admin,
            ISuperToken(address(superToken)),
            incomingFlowrate
        );

        assertEq(
            Watcher(watcher).balanceOf(alice),
            1,
            "Wrong balance by watcher"
        );

        vm.startPrank(admin);

        (, SuperToken newSuperToken) = createNewTokenPair("Test token", "TEST");

        Watcher(watcher).setPaymentToken(address(newSuperToken));

        assertEq(
            Watcher(watcher).balanceOf(alice),
            0,
            "Wrong balance by watcher after payment token change"
        );

        vm.stopPrank();
        
        fillWallet(newSuperToken, alice);

        vm.prank(alice);
        cfaLib.createFlow(
            admin,
            ISuperToken(address(newSuperToken)),
            incomingFlowrate
        );

        assertEq(
            Watcher(watcher).balanceOf(alice),
            1,
            "Wrong balance by watcher after payment token change"
        );
    }
}
