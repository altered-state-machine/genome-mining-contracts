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
[PASS] testIncreaseConsumedAmount() (gas: 41745)
[PASS] testIncreaseConsumedAmount_not_a_converter() (gas: 45276)
[PASS] testIncreaseConsumedAmount_wrong_wallet() (gas: 17061)
Test result: ok. 3 passed; 0 failed; finished in 8.30s

Running 14 tests for tests/PermissionControl.test.sol:PermissionControlTest
[PASS] testAddConsumer_from_controller() (gas: 194181)
[PASS] testAddConsumer_from_multisig() (gas: 196518)
[PASS] testAddConsumer_from_wrong_address() (gas: 14466)
[PASS] testAddManager_from_controller() (gas: 194202)
[PASS] testAddManager_from_multisig() (gas: 196539)
[PASS] testAddManager_from_wrong_address() (gas: 14446)
[PASS] testClearRole_will_revoke_all_role_members() (gas: 138024)
[PASS] testClearRole_with_existing_role() (gas: 75871)
[PASS] testRemoveConsumer_from_controller() (gas: 155813)
[PASS] testRemoveConsumer_from_multisig() (gas: 157936)
[PASS] testRemoveConsumer_from_wrong_address() (gas: 14425)
[PASS] testRemoveManager_from_controller() (gas: 155821)
[PASS] testRemoveManager_from_multisig() (gas: 157943)
[PASS] testRemoveManager_from_wrong_address() (gas: 14444)
Test result: ok. 14 passed; 0 failed; finished in 9.39s

Running 3 tests for tests/StakingStorage.test.sol:StakingStorageTestContract
[PASS] testUpdateHistory() (gas: 130580)
[PASS] testUpdateHistory_not_a_staker() (gas: 47317)
[PASS] testUpdateHistory_wrong_wallet() (gas: 17080)
Test result: ok. 3 passed; 0 failed; finished in 13.01s

Running 18 tests for tests/Converter.test.sol:ConverterTestContract
[PASS] testEnergyCalculation_with_stake_and_unstake_history() (gas: 135924)
[PASS] testEnergyCalculation_with_stake_history() (gas: 135949)
[PASS] testGetConsumedEnergy() (gas: 48274)
[PASS] testGetConsumedEnergy_wrong_wallet() (gas: 12125)
[PASS] testGetConsumedLBAEnergy() (gas: 48280)
[PASS] testGetConsumedLBAEnergy_wrong_wallet() (gas: 12159)
[PASS] testGetCurrentPeriodId_current_time_early_than_startTime() (gas: 109922)
[PASS] testGetCurrentPeriodId_current_time_in_period() (gas: 110690)
[PASS] testGetCurrentPeriodId_current_time_later_than_endTime() (gas: 110538)
[PASS] testGetCurrentPeriodId_multiple_periods() (gas: 270765)
[PASS] testGetPeriod_invalid_period_id() (gas: 19218)
[PASS] testLBAEnergyCalculation_with_lp_not_withdrawn() (gas: 127494)
[PASS] testLBAEnergyCalculation_with_lp_withdrawn() (gas: 127304)
[PASS] testPeriod_happy_path() (gas: 127496)
[PASS] testUseEnergy_happy_path() (gas: 391764)
[PASS] testUseEnergy_with_customized_lba_start_time() (gas: 3242706)
[PASS] testUseEnergy_with_lp_withdrawn_from_LBA() (gas: 362438)
[PASS] testUseEnergy_with_lp_withdrawn_from_LBA_after_first_use() (gas: 409330)
Test result: ok. 18 passed; 0 failed; finished in 16.24s

Running 11 tests for tests/Controller.test.sol:ControllerTestContract
[PASS] test_upgradeContracts_astoStorage_sol() (gas: 1469055)
[PASS] test_upgradeContracts_converter_sol() (gas: 3011295)
[PASS] test_upgradeContracts_energyStorage_sol() (gas: 1268734)
[PASS] test_upgradeContracts_lbaStorage_sol() (gas: 1268715)
[PASS] test_upgradeContracts_lpStorage_sol() (gas: 1469175)
[PASS] test_upgradeContracts_multiple_contracts_at_once() (gas: 5428985)
[PASS] test_upgradeContracts_setController() (gas: 3330525)
[PASS] test_upgradeContracts_setDao() (gas: 294368)
[PASS] test_upgradeContracts_setMultisig() (gas: 226669)
[PASS] test_upgradeContracts_staking_sol() (gas: 2655472)
[PASS] test_upgradeContracts_wrong_role() (gas: 2132683)
Test result: ok. 11 passed; 0 failed; finished in 18.34s

Running 14 tests for tests/Staking.test.sol:StakingTestContract
[PASS] testGetHistory() (gas: 357919)
[PASS] testGetTotalValueLocked() (gas: 180758)
[PASS] testStake_happy_path() (gas: 249657)
[PASS] testStake_insufficient_balance() (gas: 30854)
[PASS] testStake_zero_amount() (gas: 18826)
[PASS] testUnstake_happy_path() (gas: 261633)
[PASS] testUnstake_insufficient_balance() (gas: 167475)
[PASS] testUnstake_no_existing_history() (gas: 31371)
[PASS] testUnstake_zero_amount() (gas: 23622)
[PASS] testWithdraw_happy_path() (gas: 143)
[PASS] testWithdraw_insufficient_balance() (gas: 69589)
[PASS] testWithdraw_no_recipient() (gas: 61063)
[PASS] testWithdraw_not_an_owner() (gas: 88670)
[PASS] testWithdraw_wrong_token() (gas: 60972)
Test result: ok. 14 passed; 0 failed; finished in 18.34s
```

## Estimated gas costs

```
╭─────────────────────────────┬─────────────────┬────────┬────────┬────────┬─────────╮
│ Converter contract          ┆                 ┆        ┆        ┆        ┆         │
╞═════════════════════════════╪═════════════════╪════════╪════════╪════════╪═════════╡
│ Deployment Cost             ┆ Deployment Size ┆        ┆        ┆        ┆         │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ 2313767                     ┆ 12900           ┆        ┆        ┆        ┆         │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ Function Name               ┆ min             ┆ avg    ┆ median ┆ max    ┆ # calls │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ calculateAvailableLBAEnergy ┆ 9774            ┆ 9774   ┆ 9774   ┆ 9774   ┆ 2       │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ calculateEnergy             ┆ 13902           ┆ 13902  ┆ 13902  ┆ 13902  ┆ 2       │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ getConsumedEnergy           ┆ 866             ┆ 2957   ┆ 1523   ┆ 8023   ┆ 10      │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ getConsumedLBAEnergy        ┆ 868             ┆ 2886   ┆ 1514   ┆ 8014   ┆ 9       │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ getCurrentPeriod            ┆ 2124            ┆ 2124   ┆ 2124   ┆ 2124   ┆ 1       │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ getCurrentPeriodId          ┆ 1156            ┆ 1720   ┆ 1334   ┆ 3157   ┆ 15      │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ getPeriod                   ┆ 883             ┆ 1112   ┆ 994    ┆ 1461   ┆ 3       │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ hasRole                     ┆ 718             ┆ 718    ┆ 718    ┆ 718    ┆ 7       │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ paused                      ┆ 448             ┆ 691    ┆ 448    ┆ 2448   ┆ 41      │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ periodIdCounter             ┆ 385             ┆ 1385   ┆ 1385   ┆ 2385   ┆ 4       │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ setController               ┆ 23012           ┆ 66198  ┆ 71332  ┆ 71332  ┆ 55      │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ useEnergy                   ┆ 40501           ┆ 61925  ┆ 64166  ┆ 76123  ┆ 5       │
╰─────────────────────────────┴─────────────────┴────────┴────────┴────────┴─────────╯
╭────────────────────────┬─────────────────┬────────┬────────┬────────┬─────────╮
│ EnergyStorage contract ┆                 ┆        ┆        ┆        ┆         │
╞════════════════════════╪═════════════════╪════════╪════════╪════════╪═════════╡
│ Deployment Cost        ┆ Deployment Size ┆        ┆        ┆        ┆         │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ 963925                 ┆ 5089            ┆        ┆        ┆        ┆         │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ Function Name          ┆ min             ┆ avg    ┆ median ┆ max    ┆ # calls │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ consumedAmount         ┆ 541             ┆ 1246   ┆ 541    ┆ 2541   ┆ 34      │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ increaseConsumedAmount ┆ 3221            ┆ 21886  ┆ 23108  ┆ 32336  ┆ 12      │
╰────────────────────────┴─────────────────┴────────┴────────┴────────┴─────────╯
╭─────────────────────┬─────────────────┬────────┬────────┬────────┬─────────╮
│ Staking contract    ┆                 ┆        ┆        ┆        ┆         │
╞═════════════════════╪═════════════════╪════════╪════════╪════════╪═════════╡
│ Deployment Cost     ┆ Deployment Size ┆        ┆        ┆        ┆         │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ 2052048             ┆ 10592           ┆        ┆        ┆        ┆         │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ Function Name       ┆ min             ┆ avg    ┆ median ┆ max    ┆ # calls │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ getHistory          ┆ 0               ┆ 470    ┆ 0      ┆ 7060   ┆ 15      │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ getTokenAddress     ┆ 566             ┆ 566    ┆ 566    ┆ 566    ┆ 2       │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ getTotalValueLocked ┆ 528             ┆ 1528   ┆ 1528   ┆ 2528   ┆ 2       │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ paused              ┆ 338             ┆ 630    ┆ 338    ┆ 2338   ┆ 41      │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ stake               ┆ 2886            ┆ 75670  ┆ 62226  ┆ 132126 ┆ 11      │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ totalStakedAmount   ┆ 2484            ┆ 2484   ┆ 2484   ┆ 2484   ┆ 98      │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ unstake             ┆ 4226            ┆ 23396  ┆ 15443  ┆ 58628  ┆ 5       │
╰─────────────────────┴─────────────────┴────────┴────────┴────────┴─────────╯
╭─────────────────────────┬─────────────────┬────────┬────────┬────────┬─────────╮
│ StakingStorage contract ┆                 ┆        ┆        ┆        ┆         │
╞═════════════════════════╪═════════════════╪════════╪════════╪════════╪═════════╡
│ Deployment Cost         ┆ Deployment Size ┆        ┆        ┆        ┆         │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ 1158147                 ┆ 6069            ┆        ┆        ┆        ┆         │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ Function Name           ┆ min             ┆ avg    ┆ median ┆ max    ┆ # calls │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ getHistory              ┆ 4678            ┆ 4678   ┆ 4678   ┆ 4678   ┆ 1       │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ getStake                ┆ 992             ┆ 2103   ┆ 992    ┆ 4992   ┆ 18      │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ getUserLastStakeId      ┆ 669             ┆ 1364   ┆ 669    ┆ 2669   ┆ 23      │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ paused                  ┆ 382             ┆ 382    ┆ 382    ┆ 382    ┆ 2       │
╰─────────────────────────┴─────────────────┴────────┴────────┴────────┴─────────╯
```
