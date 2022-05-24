# ASM Genome mining

this is the contract to stake user ASTO or ASTO-USDC LP tokens to create ASTO Energy that could be spent for Gen2 brains minting.

## Audit docs

- [Product requirements](docs/product_reqs.md)
- [Glossary and project architecture](docs/glossary.md)
- [Time Contracts Use cases](docs/time_contracts_uc.md)
- [Energy Centre Contract Use cases](docs/energycentre_contract_uc.md)

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
