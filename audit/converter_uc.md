# Energy Converter contracts use cases

Status: <br>

- [x] DRAFT
- [ ] APPROVED
- [ ] SUBMITTED
- [ ] AUDITED
- [ ] PASSED & PUBLIC

## Energy Converter Manager use cases

![Energy Converter admin use cases](assets/converter_storage_uc.png)

    Manager is a DAO address, all the decisions should be made/approved by the majority of members.

### Setup new mining period `addPeriod()`

Manager can set up a new mining period: start, finish, and token multipliers.

### Update existing mining period `updatePeriod()`

Manager can update a mining period: start, finish, and token multipliers.

### Set manager / controller/ user roles (OZ AccessControl.sol)

The Manager can set/update the addresses of the logic contract that is allowed to do write operations. We use `OZ's AccessControl`.

### Pause (OZ Pausable.sol) `pause()`

The Manager can pause the contract, which should stop both, staking, and unstaking. Effectively, it means no one can withdraw their funds or add more funds.

### Unpause (OZ Pausable.sol) `unpause()` _onlyManager_

The Manager can unpause paused contract to allow staking and unstaking again.

<br>

## Energy Converter User use cases

![Staking Logic contracts use cases](assets/converter_logic_uc.png)

### Calculate the amount of energy earned so far `calculateEnergy()`

How much energy is mined by the specific user.

### Get the amount of energy already spent `getConsumedEnergy()`

Returns the amount of energy that was already spent by user.

### Get remaining energy `getEnergy()`

getEnergy = earned Energy - consumed Energy

### Get period details `getPeriod()`, `getCurrentPeriod()`, `getCurrentPeriodId()`

Details about mining period:

- `getCurrentPeriod()` - Get the current period details based on current timestamp
- `getCurrentPeriodId()` - Get the current period id based on current timestamp
- `getPeriod()` - Get period data by period id `periodId`

<br>

## Minting contract interface

### Set Minter `setUser()` _onlyManager_

The Manager can set/update the address of the logic contract that is allowed to do CRUD operations.

### Use Energy `useEnergy()` **_onlyUser_**

The minting app can call the Energy centre and request the amount of Energy accumulated by the user. That amount of energy will be transferred to the App, which means the balance of the user will decrease if the user has that amount.
