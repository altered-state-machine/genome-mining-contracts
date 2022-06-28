# Roles

## CONTROLLER_ROLE

This role assigned to the `Controller.sol`

### Responsibilites

- Initialise all contracts except controller itself
- Set new controller contract for all contracts except the Controller contract itself
- Set the Manager address for all contracts except the Controller contract itself
- Pause/unpause other contracts

<br>

## DAO_ROLE

The ASM DAO contract has this role.

### Responsibilites

- Set the DAO address for all contracts (technically, Controller set DAO, but only DAO contract can call that Controller's function)
- Set new Multisig address for Converter
- Set the new Controller contract
- Upgrade contracts
- Withdraw token

<br>

## MULTISIG_ROLE

### Responsibilites

- `Controller.sol`
  - Initialise Controller
- `Converter.sol`
  - Setting the CONSUMER_ROLE
  - Setting the MANAGER_ROLE

<br>

## MANAGER_ROLE

### Responsibilites

ASM AWS Lambda running daily

- Updating period multipliers based on market prices

<br>

## CONSUMER_ROLE

### Responsibilites

- `Staking.sol`
  - Call the updateHistory() functions in the staking storage contracts
- `Converter.sol`
  - Call the increaseConsumedAmount function in the energy storage contracts
- `Minter.sol`
  - Call the useEnergy() function in the Converter.sol
