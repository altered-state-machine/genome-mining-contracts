# Architecture

![GEN II Brains Minting event](assets/architecture.png)

In case we want to update logic we can develop and deploy a completely new logic contract with a hard-coded storage(s) address(es). We should be able to change the address of the contract that has rights to CRUD operations:

`function updateManager(address newLogicContract) external onlyOwner {}`

Replacing the Converter contract will require 2 updates, in both storages.

To decrease the number of votes required from DAO we can use the Registry contract, that can call `updateManager()` for both storages at once.

We don’t need to use it to update addresses in the logic contract, as they can be redeployed without DAO (but will still require updates in their storage).

### Pros:

low complexity, clear logic, good readability, and average development efforts.

### Cons:

Storage contracts still have some logic `updateManager()`
