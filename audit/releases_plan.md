# Patches, by releases

## Here to stay

- GMC-01 - Wrong init logic (Logic contracts DAO, Controller contract DAO)
- GMC-02 - Bypass not EOA restriction
- GMC-03 - Inheritance design allows constraint bypass
- GMC-07 - Not compatible with fee-based tokens
- GMC-08 - Wrong logic around getController
- GMC-13 - Decentralization recommendation

## Release 2

- GMC-06 - Project information leak - `config file`

## Release 3

- GMC-05 - Wrong emitted event - `Controller.sol`
- GMC-11 - Executions Cost gas optimisation - `Converter.sol`
- GMC-13 - Ensure TimeLock use - `Controller.sol`
- GMC-14 - Lack of event index - `Converter.sol`
- GMC-16 - Lack of inputs validation - `Controller.sol`, `Converter.sol`

## Not planned yet but we might fix it later on

- GMC-01 - Complicate the error detection - `all contracts`
- GMC-04 - Unbounded loop in getHistory and calculateEnergy methods - `Staking contracts`
- GMC-09 - Discrepancy with documentation - `Staking contracts`
- GMC-10 - Outdated compiler - `all contracts`
- GMC-11 - GAS optimization - `all contracts`
- GMC-12 - Code style - `all contracts`
- GMC-17 - Improvable design - `Util.sol`
- GMC-15 - Solidity literals - `TimeContstants.sol` and all contracs depending on this
