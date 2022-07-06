# Red4Sec audit report response

## GMC-01 - Wrong init logic

### Wrong DAO initialization

#### Controller's DAO

We don't need to set MULTISIG_ROLE to DAO contract during Controller initialization, as we already did this in the constructor. Later, we can update users with MULTISIG_ROLE permission by assigning it to DAO contract, when we call `setDao()`.

#### Logic contracts' DAO

We may initialize converter and staking contracts in the appropriate `setConverterLogic()` and `setStakingLogic()` functions (that are called from Controller's init()), by calling init functions of those contracts, and passing DAO address to those contracts to initialize them (see their `init()` functions).

Those specific upgrading functions `setXXXX()` are also called from the `upgradeContracts()`, so we don't forget initializing upgraded contracts.

### Complicate the error detection

We do not throw an error as the `init()` called multiple times when we need to redeploy Controller itself. This is a trade-off we aware of.

Contract upgrades:

- performed by multisig (multiple engineers are keeping an eye on what's going on here)
- all the contracts can be redeployed (the risk is reduced)

We also don't need an Event in the `init()` functions as we emit such events from the Controller.

In the future we can move the initiatilization check to the Controller while events are emitting to the logic contracts, for the sake of the design. Currently we are accepting this imperfection to avoid redeploying everything.

## GMC-02 - Bypass not EOA restriction

We deploy the Controller first, and then provide its address to all the contracts, i.e.:

```
  ...
  const controller = await deploy("Controller", {
    from: deployer,
    args: [multisig]
  });

  const astoStorage = await deploy("ASTOStakingStorage", {
    from: deployer,
    contract: "StakingStorage",
    args: [controller.address]
  });
  ...
```

Thus we have all contracts' controllers properly initialized.

When we upgrade the Controller contract, we call `setController()` functions, which sets all contracts' Controller address.

## GMC-03 - Inheritance design allows constraint bypass

We intentionally decided to move such functions to `PermissionControl.sol` and inherited them for flexibility.

We don't know what the consumers might be, so we check the addresses manually when calling `setConsumer()` function.

So we consider it not a weakness, but rather a flexibility.

## GMC-04 - Unbounded loop in getHistory and calculateEnergy methods

The scenario is technically possible but means users are behaving irrationally by staking their funds in too many (3000+) stakes, which will cost them a lot of gas.

In this case, users still can add more stakes and unstake the previous ones; the only thing affected is an Energy calculation.

In such rare cases we will address each issue individually.

## GMC-05 - Wrong emitted event

Not a critical issue , which we will address in a future release.

## GMC-06 - Project information leak

Removed

## GMC-07 - Not compatible with fee-based tokens

We are not going to support fee-based tokens in the near future.
Tokens we use: ASTO, ASTO-USDC UniSwap LP tokens.

If UniSwap tokens become supported, we will address the issue with our upgradable contracts.

## GMC-08 - Wrong logic around getController

`setController()` is only called when we upgrade the Controller contract, so `address(this)` will always return the correct address.

## GMC-09 - Discrepancy with documentation

### Comment discrepancy

We will fix this in a future release.

### Readme discrepancy

Technically, Controller sets DAO, but only the DAO contract can call that Controller's function.

## GMC- 10 - Outdated compiler

We will update the version in the future releases.

## GMC- 11 - GAS optimization

### SafeMath usage

This does not make much of a difference from a gas perspective, but we'll address this issue in future releases.

### Increase operation optimization

We'll address this issue in a future release.

### Executions Cost

Fixed for Converter.sol.
We'll fix the rest in future releases.

### Unnecessary Method

We use `currentTime()` for functional testing (on testnets) purposes. We decided to keep it.

### Dead code

Sad one. We'll fix this in a future release.

### Avoid use of unnecessary map

We use mapping for the purpose of convenience. It's a minor optimisation, but we might consider addressing it in a future release.

### Optimize revert messages

We'll shorten these in future releases.

### Use of unchecked keyword

We'll fix this in future releases.

### Logic Optimization

This was overkill. We'll get rid of that logic for future releases.

### Logic Optimization

This is a super rare usage, only for managing the Consumer role. We can optimize the logic in future releases though.

### Avoid duplicated logic

- We'll fix it in the future releases.
- Multiple valid period checks were fixed.

## GMC- 12 - Code style

### Use of constants instead of values

We can address this in future releases.

## GMC- 13 - Decentralization recommendation

### Governance Denial of Service

CONSUMER is a staking contract, it won't add a lot of history by itself.
As desribed in GMC-04, we'll address any issues where too many stakes exist case by case.

MANAGER is a ASM controlled Multisig Wallet, it won't create enough periods to cause any issues.

### Periods issues

The ASM owned Multisig wallet sets the periods and the risk of causing issues is insufficient. Every period can be changed, to reduce risks even further.

### Multiple unique role

The risk is low, as roles are transparent and managed by ASM, but we might fix this issue for future releases.

### Lack of whenNotPaused

The only contracts able to write to Storages are their appropriate logic contracts, and they are pauseable.

### Uncontrolled values

The consumer of StakingStorage is StakingLogic, whose responsibility it is to perform the calculations and record the proper amount.

### Ensure TimeLock use

Anyone can check that DAO_ROLE is assigned to the DAO contract, so the risk is low, but we might implement a timelock in future releases.

### Ensure Funds

The `withdraw()` function is designed for contract upgrades only, and controlled by DAO; the risk is considered to be low.

## GMC- 14 - Lack of event index

Fixed.

## GMC- 15 - Solidity literals

We might fix this in future releases.

## GMC- 16 - Lack of inputs validation

We'll add `setDao()` input validation in the future releases

## GMC- 17 - Improvable design

### Unnecessary hierarchy

We'll switch to `OZ Address.sol`'s `isContract()` function for future releases.

### Inconsistence logic

Init function of the Controller contract quickly validates params (the addresses are contracts).

The `upgradeContracts()` function of the Controller contract seems different, but it actually has even more strict validation, by instantiating contracts in `_setXXXX()` functions. The initial check in the `upgradeContracts()`, if the input params are contracts, provides the ability to skip some of the contracts from being upgraded.

Nevertheless, we might redesign it for future releases to make it more clear/understandable.
