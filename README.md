# ASM Genome mining

Gen II brains minting event

## Audit docs

See [audit/readme.md](audit/readme.md)

## Deployment

Prerequisites:

- multisig already created
- tokens already deployed

Steps:

1. TimeConstants.sol
2. Controller.sol (with multisig address as a manager)
3. StakingStorage.sol (x2 for asto and lp tokens) - with controller contract address
4. ConverterStorage.sol, Staking.sol, Converter.sol - with controller contract address
5. Controller.sol - call init function and supply all the addresses:
   1. astoToken,
   2. astoStorage,
   3. lpToken,
   4. lpStorage,
   5. stakingLogic,
   6. converterLogic,
   7. converterStorage
6. Converter.sol - call `addPeriod(..)` to setup period

example:

```
function setupContracts() internal {
  astoToken_ = new MockedERC20("ASTO Token", "ASTO", deployer, initialBalance);
  lpToken_ = new MockedERC20("Uniswap LP Token", "LP", deployer, initialBalance);

  controller_ = new Controller(multisig);

  staker_ = new Staking(address(controller_));
  astoStorage_ = new StakingStorage(address(controller_));
  lpStorage_ = new StakingStorage(address(controller_));
  converter_ = new Converter(address(controller_));
  converterStorage_ = new ConverterStorage(address(controller_));

  controller_.init(
    address(astoToken_),
    address(astoStorage_),
    address(lpToken_),
    address(lpStorage_),
    address(staker_),
    address(converter_),
    address(converterStorage_)
  );

  converter_.addPeriod(...);
}
```

## Testing

### Environment setup

we use Foundry for testing.
To install it: <br>

1. `$ curl -L https://foundry.paradigm.xyz | bash`
2. restart terminal
3. `$ foundryup`
4. `$ cargo install --git https://github.com/gakonst/foundry --bin forge --locked`

more details on installation here: https://github.com/foundry-rs/foundry

### Running tests

Tests are located in the /tests folders.

to run tests:
`forge test -vv`
