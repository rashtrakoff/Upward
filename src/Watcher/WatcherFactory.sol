// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.15;

import {Clones} from "openzeppelin-contracts/proxy/Clones.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {CFAv1Forwarder} from "protocol-monorepo/packages/ethereum-contracts/contracts/utils/CFAv1Forwarder.sol";
import {ISuperfluid, ISuperApp, ISuperToken} from "protocol-monorepo/packages/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {SuperAppDefinitions} from "protocol-monorepo/packages/ethereum-contracts/contracts/interfaces/superfluid/Definitions.sol";
import {IConstantFlowAgreementV1} from "protocol-monorepo/packages/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";
import {Watcher} from "./Watcher.sol";

import "forge-std/console.sol";

contract WatcherFactory is Ownable {
    error ZeroAddress();
    error InvalidName();
    error InvalidPaymentFlowrate(int96 paymentFlowrate);


    event NewWatcherCreated(
        address indexed creator,
        address watcher,
        string name,
        string symbol,
        address paymentSuperToken,
        int96 paymentFlowrate
    );
    event WatcherImplementationChanged(
        address newWatcherImplementation,
        address oldWatcherImplementation
    );


    address public immutable FORWARDER;
    address public watcherImplementation;


    constructor(
        address _cfaV1Forwarder,
        address _watcherImplementation
    ) {
        if (
            _cfaV1Forwarder == address(0) ||
            _watcherImplementation == address(0)
        ) revert ZeroAddress();

        FORWARDER = _cfaV1Forwarder;
        watcherImplementation = _watcherImplementation;
    }

    function initWatcher(
        string calldata _name,
        string calldata _symbol,
        address _paymentToken,
        int96 _paymentFlowrate
    ) external returns (address _newWatcher) {
        if (_paymentToken == address(0)) revert ZeroAddress();
        if (_paymentFlowrate < 0)
            revert InvalidPaymentFlowrate(_paymentFlowrate);
        if (bytes(_name).length == 0) revert InvalidName();

        _newWatcher = Clones.clone(watcherImplementation);

        Watcher(_newWatcher).initialize(
            _name,
            _symbol,
            msg.sender,
            _paymentToken,
            FORWARDER,
            _paymentFlowrate
        );

        emit NewWatcherCreated(
            msg.sender,
            _newWatcher,
            _name,
            _symbol,
            _paymentToken,
            _paymentFlowrate
        );
    }

    function setWatcherImplementation(address _newWatcherImplementation)
        external
        onlyOwner
    {
        if (_newWatcherImplementation == address(0)) revert ZeroAddress();

        address oldImplementation = watcherImplementation;
        watcherImplementation = _newWatcherImplementation;

        emit WatcherImplementationChanged(_newWatcherImplementation, oldImplementation);
    }
}
