// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.15;

import {SuperAppBase} from "protocol-monorepo/packages/ethereum-contracts/contracts/apps/SuperAppBase.sol";
import {CFAv1Library} from "protocol-monorepo/packages/ethereum-contracts/contracts/apps/CFAv1Library.sol";
import {Initializable} from "openzeppelin-contracts/proxy/utils/Initializable.sol";
import {ISuperfluid, ISuperApp, ISuperToken} from "protocol-monorepo/packages/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";
import {CFAv1Forwarder} from "protocol-monorepo/packages/ethereum-contracts/contracts/utils/CFAv1Forwarder.sol";
import {IConstantFlowAgreementV1} from "protocol-monorepo/packages/ethereum-contracts/contracts/interfaces/agreements/IConstantFlowAgreementV1.sol";

import "forge-std/console.sol";

contract StreamManager is SuperAppBase, Initializable {
    using CFAv1Library for CFAv1Library.InitData;

    error ZeroAddress();
    error UpdatesNotPermitted();
    error NotHost(address expectedHost, address actualCaller);
    error WrongPaymentToken(address expectedToken, address actualToken);
    error WrongAmount(int96 expectedAmount, int96 actualAmount);
    error InvalidPaymentFlowrate(int96 paymentFlowrate);
    error NotCreator(address caller, address creator);
    error FlowrateChangeFailed(int96 newFlowrate, int96 oldFlowrate);

    event PaymentTokenChanged(
        address newPaymentSuperToken,
        address oldPaymentSuperToken
    );
    event PaymentFlowrateChanged(
        int96 newPaymentFlowrate,
        int96 oldPaymentFlowrate
    );
    event SubscriptionCreated(address subscriber);
    event SubscriptionTerminated(address subscriber);
    event TerminationFailedWithReason(string reason);
    event TerminationFailedWithData(bytes data);

    CFAv1Forwarder public FORWARDER;

    CFAv1Library.InitData public CFA_V1;

    address public HOST;

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
        address _host,
        address _cfa,
        int96 _paymentFlowrate
    ) external initializer {
        FORWARDER = CFAv1Forwarder(_forwarder);
        HOST = _host;
        CREATOR = _creator;
        CFA_V1 = CFAv1Library.InitData({
            host: ISuperfluid(_host),
            cfa: IConstantFlowAgreementV1(_cfa)
        });
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
            (FORWARDER.getFlowrate(paymentToken, _subscriber, address(this)) >=
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

    function terminationHook(bytes memory _ctx)
        external
        returns (bytes memory _newCtx)
    {
        _newCtx = _ctx;

        // NOTE: We are assuming that only this contract can call this method.
        // Actually, it's the Host contract that leads to this contract triggering this method.
        if (msg.sender == address(this)) {
            ISuperToken cachedPaymentToken = paymentToken;
            CFAv1Forwarder forwarder = FORWARDER;
            address creator = CREATOR;
            int96 oldCreatorIncomingFlowrate = forwarder.getFlowrate(
                cachedPaymentToken,
                address(this),
                creator
            );
            int96 oldOutgoingFlowrate = forwarder.getAccountFlowrate(
                cachedPaymentToken,
                address(this)
            );

            // As `oldOutgoingFlowrate` should be -ve, we can directly add it.
            int96 newCreatorIncomingFlowrate = oldCreatorIncomingFlowrate +
                oldOutgoingFlowrate;

            // Decrease the flowrate to the creator.
            if (newCreatorIncomingFlowrate == int96(0)) {
                _newCtx = CFA_V1.deleteFlowWithCtx(
                    _newCtx,
                    address(this),
                    creator,
                    cachedPaymentToken
                );
            } else {
                _newCtx = CFA_V1.updateFlowWithCtx(
                    _newCtx,
                    creator,
                    cachedPaymentToken,
                    newCreatorIncomingFlowrate
                );
            }
        }
    }

    function _checkCreator(address _caller) internal view {
        address creator = CREATOR;

        if (_caller != creator) revert NotCreator(_caller, creator);
    }

    /******************************************************
     *               Superfluid Callbacks                  *
     ******************************************************/

    // TODO: Start a stream to the creator.
    function afterAgreementCreated(
        ISuperToken _superToken,
        address, /*_agreementClass*/
        bytes32, /*_agreementId*/
        bytes calldata _agreementData,
        bytes calldata, /*_cbdata*/
        bytes calldata _ctx
    ) external override returns (bytes memory _newCtx) {
        _newCtx = _ctx;

        address host = HOST;
        if (msg.sender != host) revert NotHost(host, msg.sender);

        ISuperToken cachedPaymentToken = paymentToken;
        CFAv1Forwarder forwarder = FORWARDER;
        (address subscriber, ) = abi.decode(_agreementData, (address, address));

        // Check if the payment token is correct.
        if (_superToken != cachedPaymentToken)
            revert WrongPaymentToken(
                address(cachedPaymentToken),
                address(_superToken)
            );

        // Check if the amount going to be streamed is correct.
        int96 incomingFlowrate = forwarder.getFlowrate(
            cachedPaymentToken, // token
            subscriber, // sender
            address(this) // receiver
        );

        if (incomingFlowrate < paymentFlowrate)
            revert WrongAmount(paymentFlowrate, incomingFlowrate);

        address creator = CREATOR;

        int96 creatorRate = forwarder.getFlowrate(
            cachedPaymentToken,
            address(this),
            creator
        );

        // Increase the flowrate to creator.
        // Note: If the subscriber is the first one, you need to create a flow else, update the flow.
        if (creatorRate != int96(0)) {
            _newCtx = CFA_V1.updateFlowWithCtx(
                _newCtx,
                CREATOR,
                paymentToken,
                creatorRate + incomingFlowrate
            );
        } else {
            _newCtx = CFA_V1.createFlowWithCtx(
                _newCtx,
                CREATOR,
                paymentToken,
                incomingFlowrate
            );
        }

        emit SubscriptionCreated(subscriber);
    }

    // TODO: Permit updates if new `paymentFlowrate` < user's current flowrate.
    function afterAgreementUpdated(
        ISuperToken, /*_superToken*/
        address, /*_agreementClass*/
        bytes32, /*_agreementId*/
        bytes calldata, /*_agreementData*/
        bytes calldata, /*_cbdata*/
        bytes calldata /*_ctx*/
    )
        external
        pure
        override
        returns (
            bytes memory /*_newCtx*/
        )
    {
        revert UpdatesNotPermitted();
    }

    function afterAgreementTerminated(
        ISuperToken, /*_superToken*/
        address, /*_agreementClass*/
        bytes32, /*_agreementId*/
        bytes calldata _agreementData,
        bytes calldata, /*_cbdata*/
        bytes calldata _ctx
    ) external override returns (bytes memory _newCtx) {
        _newCtx = _ctx;

        try this.terminationHook(_newCtx) returns (bytes memory _modCtx) {
            _newCtx = _modCtx;
            (address subscriber, ) = abi.decode(
                _agreementData,
                (address, address)
            );

            emit SubscriptionTerminated(subscriber);
        } catch Error(string memory _reason) {
            emit TerminationFailedWithReason(_reason);
        } catch (bytes memory _data) {
            emit TerminationFailedWithData(_data);
        }
    }
}
