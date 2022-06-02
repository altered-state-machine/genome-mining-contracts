# ASM Genome mining

Gen II brains minting event

## Audit docs

See [audit/readme.md](audit/readme.md)

## Deployment

Prerequisites:

- multisig already created

1. Tokens.sol, TimeConstants.sol
2. StakingStorage.sol, ConverterStorage.sol, Staking.sol, Converter.sol
3. Controller.sol (it will require addresses from 2)
4. Staking.sol: `init(registryAddress, stakingStorageAddress)`
5. StakingStorage.sol: `init(registryAddress, stakingAddress)`
6. Converter.sol: `init(registryAddress, converterStorageAddress)`
7. ConverterStorage.sol: `init(registryAddress, converterAddress)`

to be continue...

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
