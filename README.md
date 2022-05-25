# ASM Genome mining

Gen II brains minting event

## Audit docs

See [audit/readme.md](audit/readme.md)

## Deployment

Prerequisites:

- multisig already created

1. Tokens.sol, TimeConstants.sol
2. StakingStorage.sol, ConverterStorage.sol
3. Staking.sol, Converter.sol
4. Registry.sol
5. Staking.sol: `init(registryAddress, stakingStorageAddress)`
6.

## Testing

we use Foundry for testing.
To install it: <br>

1. `$ curl -L https://foundry.paradigm.xyz | bash`
2. restart terminal
3. `$ foundryup`
4. `$ cargo install --git https://github.com/gakonst/foundry --bin forge --locked`

more details on installation here: https://github.com/foundry-rs/foundry

to run tests:
`forge test -vv`
