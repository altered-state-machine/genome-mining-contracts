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

```

Running 3 tests for tests/EnergyStorage.test.sol:EnergyStorageTestContract
[PASS] testIncreaseConsumedAmount() (gas: 41777)
[PASS] testIncreaseConsumedAmount_not_a_converter() (gas: 45220)
[PASS] testIncreaseConsumedAmount_wrong_wallet() (gas: 17005)
Test result: ok. 3 passed; 0 failed; finished in 8.40s

Running 3 tests for tests/StakingStorage.test.sol:StakingStorageTestContract
[PASS] testUpdateHistory() (gas: 130470)
[PASS] testUpdateHistory_not_a_staker() (gas: 47262)
[PASS] testUpdateHistory_wrong_wallet() (gas: 17025)
Test result: ok. 3 passed; 0 failed; finished in 11.88s

Running 3 tests for tests/Controller.test.sol:ControllerTestContract
[PASS] testUpgradeContracts_staking_sol() (gas: 265091)
[PASS] testUpgradeContracts_wrong_role() (gas: 48293)
[PASS] test_beforeAll() (gas: 164)
Test result: ok. 3 passed; 0 failed; finished in 14.49s

Running 17 tests for tests/Converter.test.sol:ConverterTestContract
[PASS] testEnergyCalculation_with_stake_and_unstake_history() (gas: 135964)
[PASS] testEnergyCalculation_with_stake_history() (gas: 136011)
[PASS] testGetConsumedEnergy() (gas: 48284)
[PASS] testGetConsumedEnergy_wrong_wallet() (gas: 12103)
[PASS] testGetConsumedLBAEnergy() (gas: 48312)
[PASS] testGetConsumedLBAEnergy_wrong_wallet() (gas: 12137)
[PASS] testGetCurrentPeriodId_current_time_early_than_startTime() (gas: 109901)
[PASS] testGetCurrentPeriodId_current_time_in_period() (gas: 110603)
[PASS] testGetCurrentPeriodId_current_time_later_than_endTime() (gas: 110495)
[PASS] testGetCurrentPeriodId_multiple_periods() (gas: 270413)
[PASS] testGetPeriod_invalid_period_id() (gas: 19286)
[PASS] testLBAEnergyCalculation_with_lp_not_withdrawn() (gas: 125250)
[PASS] testLBAEnergyCalculation_with_lp_withdrawn() (gas: 125038)
[PASS] testPeriod_happy_path() (gas: 127411)
[PASS] testUseEnergy_happy_path() (gas: 299271)
[PASS] testUseEnergy_with_lp_withdrawn_from_LBA() (gas: 267244)
[PASS] testUseEnergy_with_lp_withdrawn_from_LBA_after_first_use() (gas: 313395)
Test result: ok. 17 passed; 0 failed; finished in 14.78s

Running 15 tests for tests/Staking.test.sol:StakingTestContract
[PASS] testGetHistory() (gas: 357534)
[PASS] testGetTotalValueLocked() (gas: 180521)
[PASS] testStake_happy_path() (gas: 249387)
[PASS] testStake_insufficient_balance() (gas: 30853)
[PASS] testStake_zero_amount() (gas: 18803)
[PASS] testUnstake_happy_path() (gas: 260849)
[PASS] testUnstake_insufficient_balance() (gas: 167163)
[PASS] testUnstake_no_existing_history() (gas: 29149)
[PASS] testUnstake_zero_amount() (gas: 21407)
[PASS] testWithdraw_happy_path() (gas: 143)
[PASS] testWithdraw_insufficient_balance() (gas: 67756)
[PASS] testWithdraw_no_recipient() (gas: 59252)
[PASS] testWithdraw_not_an_owner() (gas: 86859)
[PASS] testWithdraw_not_paused() (gas: 19722)
[PASS] testWithdraw_wrong_token() (gas: 59139)
Test result: ok. 15 passed; 0 failed; finished in 15.77s
```
