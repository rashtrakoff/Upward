// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.15;

import "../helpers/SimpleSetup.sol";
import "forge-std/console.sol";

contract SimpleStreamManagerTest is Test, Setup {
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
            forwarder.getAccountFlowrate(superToken, streamManager),
            2 * incomingFlowrate,
            "Manager's incoming rate is incorrect"
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
            forwarder.getAccountFlowrate(superToken, streamManager),
            0,
            "Manager's incoming rate is incorrect"
        );
    }

    function testWithdrawPaymentsPartialSingle() public {
        address streamManager = _createStreamManager();
        CFAv1Library.InitData storage cfaLib = sf.cfaLib;
        int96 incomingFlowrate = _convertToRate(1e10);

        vm.prank(alice);
        cfaLib.createFlow(
            streamManager,
            ISuperToken(address(superToken)),
            incomingFlowrate
        );

        skip(3600 * 24);

        uint256 managerBalance = ISuperToken(address(superToken)).balanceOf(streamManager);
        uint256 streamedAmount = uint256(uint96(incomingFlowrate * (3600 * 24)));

        assertEq(
            managerBalance,
            streamedAmount,
            "Wrong balance in manager contract"
        );

        uint256 prevCreatorBalance = ISuperToken(address(superToken)).balanceOf(admin);

        vm.prank(admin);
        SimpleStreamManager(streamManager).withdrawPayments(managerBalance / 2);
        
        assertEq(
            ISuperToken(address(superToken)).balanceOf(admin),
            prevCreatorBalance + managerBalance / 2,
            "Wrong creator balance"
        );
    }

    function testWithdrawPaymentsPartialBulk() public {
        address streamManager = _createStreamManager();
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

        skip(3600 * 24);

        uint256 managerBalance = ISuperToken(address(superToken)).balanceOf(streamManager);
        uint256 streamedAmount = 2 * uint256(uint96(incomingFlowrate * (3600 * 24)));

        assertEq(
            managerBalance,
            streamedAmount,
            "Wrong balance in manager contract"
        );

        uint256 prevCreatorBalance = ISuperToken(address(superToken)).balanceOf(admin);

        vm.prank(admin);
        SimpleStreamManager(streamManager).withdrawPayments(managerBalance / 2);
        
        assertEq(
            ISuperToken(address(superToken)).balanceOf(admin),
            prevCreatorBalance + managerBalance / 2,
            "Wrong creator balance"
        );
    }

    function testWithdrawPaymentsFullSingle() public {
        address streamManager = _createStreamManager();
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

        skip(3600 * 24);

        uint256 managerBalance = ISuperToken(address(superToken)).balanceOf(streamManager);
        uint256 streamedAmount = 2 * uint256(uint96(incomingFlowrate * (3600 * 24)));

        assertEq(
            managerBalance,
            streamedAmount,
            "Wrong balance in manager contract"
        );

        uint256 prevCreatorBalance = ISuperToken(address(superToken)).balanceOf(admin);

        vm.prank(admin);
        SimpleStreamManager(streamManager).withdrawPayments(type(uint256).max);
        
        assertEq(
            ISuperToken(address(superToken)).balanceOf(admin),
            prevCreatorBalance + managerBalance,
            "Wrong creator balance"
        );
    }

    function testWithdrawPaymentsFullBulk() public {
        address streamManager = _createStreamManager();
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

        skip(3600 * 24);

        uint256 managerBalance = ISuperToken(address(superToken)).balanceOf(streamManager);
        uint256 streamedAmount = 2 * uint256(uint96(incomingFlowrate * (3600 * 24)));

        assertEq(
            managerBalance,
            streamedAmount,
            "Wrong balance in manager contract"
        );

        uint256 prevCreatorBalance = ISuperToken(address(superToken)).balanceOf(admin);

        vm.prank(admin);
        SimpleStreamManager(streamManager).withdrawPayments(type(uint256).max);
        
        assertEq(
            ISuperToken(address(superToken)).balanceOf(admin),
            prevCreatorBalance + managerBalance,
            "Wrong creator balance"
        );
    }
}
