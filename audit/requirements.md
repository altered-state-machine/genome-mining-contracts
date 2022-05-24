# Project requirements

Status: <br>

- [x] DRAFT
- [ ] APPROVED
- [ ] SUBMITTED
- [ ] AUDITED
- [ ] PASSED & PUBLIC

## Business Requirements

The Gen II brains minting event is going to have 3 mining periods and 3 minting windows. Each window has predefined 30.000 brains to be minted.

After Mining 1 is over, the Mining period 2 AND Minting Window 1 start.

Energy minted during Mining period becomes available during Minting window.

![GEN II Brains Minting event](assets/event.png)

The energy and brains left non-minted from the previous Window will migrate to the next Minting period.

Brains left after Window 3 can be withdrawn by the ASM and, probably, traded openly for ASTO OR destroyed.

Time that tokens remained staked will be mapped to the Energy in a 1:1 ratio.

Still, we want to use token multiplier to reward ASTO or LP token holders differently. Token multiplier is setup on contract deployment but can be changed by contract owner (DAO).

<br>

## Technical requirements

Dev team is required to keep things simple and focus mainly on delivering CURRENT PROJECT business objectives rather on all possible features and flexibility.

### Separation of concerns

It is quite possible, that we will decide to redeploy some contracts to change the logic.
Because of that, we want to separate logic and storage.

Most probable we’ll have separated staking and calculations.

### Minting contract

For the time of development we have just one application for the Energy - the minting Gen II brains.

We are not implementing any features to support future applications, but rather consider the current project as an iterative prototype for future platform development.

### Testing

We should have tests covering all the financially crucial functionality.

Separate storage and logic allows us to use unit tests extensively. It is also important to test out time-bound logic using test helpers as we did with LBA functional testing (scripts + test helpers + etherscan)

## Deadlines

We are required to have working tools (FE and smart contracts) to start mining Energy for the future minting event before June 6.
