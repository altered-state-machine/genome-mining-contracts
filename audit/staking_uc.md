# Staking contracts use cases

Status: <br>

- [x] DRAFT
- [ ] APPROVED
- [ ] SUBMITTED
- [ ] AUDITED
- [ ] PASSED & PUBLIC

## Staking Storage use cases

![Staking Storage contracts use cases](assets/staking_storage_uc.png)

    Owner is a DAO address, all the decisions should be made/approved by the majority of members.

### Update staking history (CRUD operation) `updateHistory()` **_onlyManager_**

A Manager (logic contract) can set/update the staking history of specified wallet.

### Set token address `setToken()` _onlyOwner_

An Owner can set/update the address of the token.

### Set storage manager `setManager()` _onlyOwner_

An Owner can set/update the address of the logic contract that is allowed to do CRUD operations.

### Pause (OZ Pausable.sol) `pause()` _onlyOwner_

An Owner can pause the contract, which should stop both, staking, and unstaking. Effectively, it means no one can withdraw their funds or add more funds.

### Unpause (OZ Pausable.sol) `unpause()` _onlyOwner_

An Owner can unpause paused contract to allow staking and unstaking again.

### Transfer ownership (OZ Ownable.sol) `transferOwnership()` _onlyOwner_

It will be done at least once, automatically, at contract creation. After the contract was created, the ownership will be transferred to the specified address DAO.

<br>

## Staking Logic contract use cases

![Staking Logic contracts use cases](assets/staking_logic_uc.png)

### Stake tokens `stake()`

Staking is the process of locking your ASTO or LP tokens in the contract.
Users can add more tokens (increase their stake) anytime.

### Unstake tokens `unstake()`

Unstaking is the process of unlocking (getting back) your tokens.
Users can arbitrarily decrease the amount of staked tokens, up to 0.

### Get the total amount of tokens staked in the contract `getTotalValueLocked()`

How many tokens are staked in the contract right now.

### Withdraw token `withdraw()` _onlyOwner_

An Owner can withdraw unclaimed tokens to the specified address. Storage balance is not affected.

### Forced unstake `forceUnstake()` _onlyOwner_

An Owner can unstake tokens and send them to the specified address. Stake balance will be updated.

### Set token address `setToken()` _onlyOwner_

An Owner can set/update the address of the token.
