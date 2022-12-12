## Introduction

Enable subscription based token-gating for your content powered by Superfluid.

## Deployments

| Chain           | Names                                                                                                                                          |
|-----------------|------------------------------------------------------------------------------------------------------------------------------------------------|
| Polygon Mainnet | StreamManagerFactory: 0x222fa45e148Bb5E23f5E10b6bc27a47Ca55f4EcB<br>StreamManager (implementation): 0xAed83Fd76188a16Aa55c60b38c19887f91411ccB |

## How To Use The Contracts

As a creator, call the `initStreamManager` method in the `StreamManagerFactory` contract and create a `StreamManager` clone for yourself. Subscribers can start a stream directly to the `StreamManager` clone of a creator provided the payment flowrate matches the one specified in that contract by the creator. Failing to match the `paymentFlowrate` will cause the transaction to revert.

If you have any more queries, please contact me on Discord (rashtrakoff#2547)
