## Introduction

Enable subscription based token-gating for your content powered by Superfluid.

## Deployments

| Chain           | Names                                                                                                                                          |
|-----------------|------------------------------------------------------------------------------------------------------------------------------------------------|
| Polygon Mainnet | WatcherFactory: 0x06DfA8378c49835d9e2f3Ad27Cc8936E1A3f5c20<br>Watcher (implementation): 0x7cB1b6dC620c2bC4d63b32a83427D2C30f0a3373 |

## How To Use The Contracts

As a creator, call the `initWatcher` method in the `WatcherFactory` contract and create a `Watcher` clone for yourself. Subscribers can start a stream directly to the `CREATOR` of the clone and make sure that the payment flowrate at least matches the one specified in that contract by the creator. Failing to match the `paymentFlowrate` will cause the `balanceOf` function in the watcher clone contract return `0` which would mean that the subscriber doesn't have the access to the token-gated content.

If you have any more queries, please contact me on Discord (rashtrakoff#2547).
