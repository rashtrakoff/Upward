// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.15;

import {SuperAppBase} from "protocol-monorepo/packages/ethereum-contracts/contracts/apps/SuperAppBase.sol";
import {CFAv1Library} from "protocol-monorepo/packages/ethereum-contracts/contracts/apps/CFAv1Library.sol";
import {Initializable} from "openzeppelin-contracts/proxy/utils/Initializable.sol";
import {ISuperfluid, ISuperApp, ISuperToken} from "protocol-monorepo/packages/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {CFAv1Forwarder} from "protocol-monorepo/packages/ethereum-contracts/contracts/utils/CFAv1Forwarder.sol";
import {IConstantFlowAgreementV1} from "protocol-monorepo/packages/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

import "forge-std/console.sol";

contract Watcher is Initializable {
    using CFAv1Library for CFAv1Library.InitData;


    error ZeroAddress();
    error UpdatesNotPermitted();
    error WrongPaymentToken(address expectedToken, address actualToken);
    error WrongAmount(int96 expectedAmount, int96 actualAmount);
    error InvalidPaymentFlowrate(int96 paymentFlowrate);
    error NotCreator(address caller, address creator);
    error FlowrateChangeFailed(int96 newFlowrate, int96 oldFlowrate);
    error PaymentWithdrawalFailed(uint256 amount);


    event PaymentTokenChanged(
        address newPaymentSuperToken,
        address oldPaymentSuperToken
    );
    event PaymentFlowrateChanged(
        int96 newPaymentFlowrate,
        int96 oldPaymentFlowrate
    );


    CFAv1Forwarder public FORWARDER;

    address public CREATOR;

    ISuperToken public paymentToken;

    // The following two variable are required for token gating purposes.
    // Ex: paragraph.xyz uses these variables to validate a contract for token gating
    // purposes.
    string public name;
    string public symbol;

    int96 paymentFlowrate;


    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _creator,
        address _paymentToken,
        address _forwarder,
        int96 _paymentFlowrate
    ) external initializer {
        FORWARDER = CFAv1Forwarder(_forwarder);
        CREATOR = _creator;
        name = _name;
        symbol = _symbol;
        paymentToken = ISuperToken(_paymentToken);
        paymentFlowrate = _paymentFlowrate;
    }

    function balanceOf(address _subscriber)
        public
        view
        returns (uint256 _isSubscribed)
    {
        // This is akin to a boolean check. We are checking whether a subscriber is streaming
        // the minimum acceptable amount of payment token to the creator.
        return
            (FORWARDER.getFlowrate(paymentToken, _subscriber, CREATOR) >=
                paymentFlowrate)
                ? 1
                : 0;
    }

    function setPaymentToken(address _newPaymentSuperToken) external {
        _checkCreator(msg.sender);
        if (_newPaymentSuperToken == address(0)) revert ZeroAddress();

        address oldPaymentToken = address(paymentToken);
        paymentToken = ISuperToken(_newPaymentSuperToken);

        emit PaymentTokenChanged(_newPaymentSuperToken, oldPaymentToken);
    }

    // NOTE: If the content creator gives 0 as `_newPaymentFlowrate` it means anyone can
    // view the gated publications.
    function setPaymentFlowrate(int96 _newPaymentFlowrate) external {
        _checkCreator(msg.sender);
        if (_newPaymentFlowrate < 0)
            revert InvalidPaymentFlowrate(_newPaymentFlowrate);

        int96 oldPaymentFlowrate = paymentFlowrate;
        paymentFlowrate = _newPaymentFlowrate;

        emit PaymentFlowrateChanged(_newPaymentFlowrate, oldPaymentFlowrate);
    }

    function _checkCreator(address _caller) internal view {
        address creator = CREATOR;

        if (_caller != creator) revert NotCreator(_caller, creator);
    }
}