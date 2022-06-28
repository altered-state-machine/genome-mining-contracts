# Red4Sec audit report response

## GMC-01 - Wrong init logic

### Wrong DAO initialization

#### Controller's DAO

We don't need to set MULTISIG_ROLE to DAO contract during Controller initialization, as we already did it in constructor. Later, we update users with MULTISIG_ROLE permission by assigning it to DAO contract, when we call `setDao()`.

#### Logic contracts' DAO

We initialize converter and staking contracts in the appropriate `setConverterLogic()` and `setStakingLogic()` functions (that are called from Controller's init()), by calling init functions of those contracts, and passing DAO address to those contracts to initialize them (see their `init()` functions).

Those specific upgrading functions `setXXXX()` are also called from the `upgradeContracts()`, so we don't forget initializing upgraded contracts.

### Complicate the error detection

We do not throw an error as the `init()` called multiple times when we need to redeploy Controller itself. It's a trade off we aware of.

Contract upgrades:

- performed by multisig (multiple engineers are keeping an eye on what's going on)
- all the contracts can be redeployed (the risk is reduced)

We also don't need an Event in the `init()` functions as we emit such events from the Controller.

In the future we can move initiatilization check to the Controller, while events emitting to the logic contracts, for the sake of the design. Right now we are accepting this unperfectness to avoid redeploying everything.

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

When we upgrade the Controller contract, we call `setController()` functions, that sets all contracts' Controller address.

## GMC-03 - Inheritance design allows constraint bypass

We intentionally decided to move such functions to `PermissionControl.sol` and inherited them for flexibility.

We don't know what consumers might be, so we check the addresses manually when calling `setConsumer()` function.

So we consider it not a weakness but flexibility.

## GMC-04 - Unbounded loop in getHistory and calculateEnergy methods

The scenario is technically possible, but mean users behave irrational, by staking their funds in too many (3000+) stakes, which will cost them a lot of gas.

In case it happens, users still can add more stakes and unster the previous ones; the only thing is affected is an energy calculation.

In such rare cases we'll address the issues individually.

## GMC-05 - Wrong emitted event

Not a critical issue that we'll address in a future release.

## GMC-06 - Project information leak

Removed

## GMC-07 - Not compatible with fee-based tokens

We are not going to suport fee based tokens in the nearest future.
Tokens we use: ASTO, Uniswap LP.

If Uniswap tokens will start support it we'll address the issue with our upgradable contracts.

## GMC-08 - Wrong logic around getController

`setController()` is only called when we upgrade the Controller contract, so `address(this)` will always return the correct address.

## GMC-09 - Discrepancy with documentation

### Comment discrepancy

We'll fix it in the future releases.

### Readme discrepancy

Technically, Controller set DAO, but only DAO contract can call that Controller's function.

## GMC- 10 - Outdated compiler

We are going to update the version in the future releases.

## GMC- 11 - GAS optimization

### SafeMath usage

Not much difference from the gas perspective, but we'll address this issue in the future releases.

### Increase operation optimization

We'll address that issue in the future releases.

### Executions Cost

Fixed for Converter.sol.
We'll fix the rest in the future releases.

### Unnecessary Method

We use `currentTime()` for the functional testing (on testnets) purpose. We decided to keep it.

### Dead code

Sad one. We'll fix it in the future releases.

### Avoid use of unnecessary map

We use mapping for the convinience. It's a minor optimisation, but we might consider to address it in the future releases.

### Optimize revert messages

We'll shorten them in the future releases.

### Use of unchecked keyword

We'll fix it in the future releases.

### Logic Optimization

It was an overkill. We'll get rid of that logic in the future releases.

### Logic Optimization

Super rare usage, only for managing Consumer role. We can optimize the logic in the future releases though.

### Avoid duplicated logic

- We'll fix it in the future releases.
- multiple valid period checks were fixed.

## GMC- 12 - Code style

### Use of constants instead of values

We can address it in the future releases.

## GMC- 13 - Decentralization recommendation

### Governance Denial of Service

CONSUMER is a staking contract, it won't add too many history by itself.
As desribed in GMC-04, we'll address the issue when too many stakes exist case by case.

MANAGER is a ASM controlled Multisig Wallet, it won't create too many periods to make troubles for itself.

### Periods issues

ASM owned Multisig wallet sets the periods, the risk of getting in troubles is insufficient, and every period can be changed, to reduce risks even further.

### Multiple unique role

The risk is low, as roles are transparent and managed by ASM, but we might fix this issue in the future releases.

### Lack of whenNotPaused

The only contracts able to write to Storages are their appropriate logic contracts, and they are pauseable.

### Uncontrolled values

The consumer of StakingStorage is StakingLogic, whose responsibility it is to perform the calculations and record the proper amount.

### Ensure TimeLock use

Anyone can check that DAO_ROLE is assigned to DAO contract, so the risk is low, but we might implement a time lock in the future releases.

### Ensure Funds

The `withdraw()` function is designed for contracts upgrade only, and controlled by DAO; the risk is considered to be low.

## GMC- 14 - Lack of event index

Fixed.

## GMC- 15 - Solidity literals

We might fix it in the future releases.

## GMC- 16 - Lack of inputs validation

We'll add `setDao()` input validation in the future releases

## GMC- 17 - Improvable design

### Unnecessary hierarchy

We'll switch to `OZ Address.sol`'s `isContract()` function in the future releases.

### Inconsistence logic

Init function of the Controller contract quickly validate params (the addresses are contracts).

The `upgradeContracts()` function of the Controller contract seems different, but it actually has even more strict validation, by instantiating contracts in `_setXXXX()` functions. The initial check in the `upgradeContracts()` if the input params are contracts, allows to skip some of the contracts from being upgraded.

Nevertheless, we might redesign it in the future releases to make it more clear/understandable.
