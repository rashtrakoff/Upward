## Introduction

Enable subscription based token-gating for your content powered by Superfluid.

## Deployments

| Chain           | Names                                                                                                                                          |
|-----------------|------------------------------------------------------------------------------------------------------------------------------------------------|
| Polygon Mainnet | WatcherFactory: 0x5bbf63bA91D8a0E0C90f1535506F385b2DaBAAC6<br>Watcher (implementation): 0xFC7be25d818380cf551eD3dac0a45E2471BB0e3d |

To deploy the contracts and verify them, use the following line of command:

```
forge script script/DeployWatcher.s.sol:DeployWatcherScript --rpc-url $POLYGON_RPC_URL --broadcast -vvvv --verify --etherscan-api-key $POLYGONSCAN_API_KEY --slow --with-gas-price 50000000000
```

Somehow, using the following line of code *doesn't* work:

```
forge script script/DeployWatcher.s.sol:DeployWatcherScript --rpc-url $POLYGON_RPC_URL --broadcast -vvvv --verify --etherscan-api-key $POLYGONSCAN_API_KEY
```

It throws the following error:

`(code: -32000, message: insufficient funds for gas * price + value, data: None)`

## How To Use The Contracts

As a creator, call the `initWatcher` method in the `WatcherFactory` contract and create a `Watcher` clone for yourself. Subscribers can start a stream directly to the `CREATOR` of the clone and make sure that the payment flowrate at least matches the one specified in that contract by the creator. Failing to match the `paymentFlowrate` will cause the `balanceOf` function in the watcher clone contract return `0` which would mean that the subscriber doesn't have the access to the token-gated content.

If you have any more queries, please contact me on Discord (rashtrakoff#2547).
