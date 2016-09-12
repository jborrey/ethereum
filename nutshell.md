# Ethereum in a Nutshell

Ethereum is a blockchain based protocol, like bitcoin, which can run Turing complete decentralised trustless applications. The decentralisation ensures that applications always continues to operate but I think the _trustless_ aspect is more important. One can now program how money moves and the way in which people financially interact. To do this previously, because of regulation and because people don't trust strangers with their money, the barrier to entry of this field was very high. You had be a bank or a company with lawyers and funding. With ethereum, anyone can create a financial service (or much more such as decentralised communities, markets, governments) and anyone can choose to be a consumer of this product.

When bitcoin came into existence, finally, anyone could send and receive payments online. But if you sent bitcoin to a particular address you had to trust that the person receiving the bitcoin was doing what they agreed to (maybe delivering a product, maybe providing a digital service). With ethereum on the other hand, you could inspect contract code, and be sure of what it does and be sure that exactly that code will be run when you activate it by sending ether to it. Since computation in general can be trustless, not just money can be programmed but the actual flow of data (perhaps authorizations, condition based actions, etc.) can be programmed. It might be hard to completely understand the nuance immediately but lesson 3 will show you an application that simply cannot be built without ethereum. There are also some good resources out there such as [this podcast](http://a16z.com/2016/08/28/ethereum/).

The sections below explain some general concepts in ethereum. For a comprehensive overlook, I recommend reading the [Ethereum White Paper](https://github.com/ethereum/wiki/wiki/White-Paper).

### Block Explorers
Before explaining the concepts of ethereum we should first look at a _block explorer_. Ethereum, being a blockchain based protocol means that all state of the network is contained in the blockchain and so explaining the concepts below will be easier when you can see some real data. A _block explorer_ is an application/website which specializes in displaying blockchain data. For ethereum, the leading 2 explorers are [Etherscan](https://testnet.etherscan.io/) and [Ether Camp](https://live.ether.camp/).

### Accounts
The blockchain of Ethereum is really a trustless [storage of account addresses and balances](https://etherscan.io/accounts) which anyone can publicly inspect. You could imagine some sort of (simplified) map like:
```json
{
  "0x1d3cf115e2777dd104ef0a61d0dc2ba78229b161": 23.9238,
  "0xaa1a6e3e6ef20068f7f8d8c835d2d22fd5116444": 89.8932,
}
```

Every time a block is mined and added to the chain, some set of account balances will be updated. There are two types of accounts. The first type is the more traditional cryptocurrency account where a user generates an asymmetric key pair, the public key is hashed to get an address and the private key can be used to move coins. The other type of account that exists is one owned and controlled by contracts. When a contract is deployed to the network it will exist _at_ and address and only contract code can send money out from this account.

Addresses are 20 random bytes and when you create an account your wallet software will generate an address for you. The blockchain does not know that this address exists yet. That is fine and at the time, the balance is implicitly 0. When a transaction is made that sends ether to your address, your address and new balance will be part of the blockchain's map/state.

Closer inspection of an [arbitrary account](https://etherscan.io/address/0x7aa534c9b18d6f4117301971962986467e74eed1) on Etherscan will the current balance and all of the transaction history.

### Transactions
A transaction is piece of data, created by a user and submitted to the network that has the ability to change the state of the blockchain. For example, a transaction of me sending you 5 ether would authorize the blockchain to be updated such that my balance goes down by 5 and yours goes up by 5. Contracts can also create transactions (more correctly these are _messages_) which will change the balance of the contract and probably increase the balance of another user. In a serpent contract for example, the code `send(addr, amount)` will send `amount` ether to `addr`. The complexity of a transaction in terms of formatting, digital signatures, etc. is abstracted away from you when you use a wallet or program a contract to send. The ID of all transactions on the blockchain is a hash of the formated data packet, for example, [0x124d299b173bd861836a2b610005ccacc7ce9fc8cfa1d4bd189c94730bd6f088](https://etherscan.io/tx/0x124d299b173bd861836a2b610005ccacc7ce9fc8cfa1d4bd189c94730bd6f088). A more indepth look at transaction data is at the end of the `Miners & Gas` section below.

### Contracts
Contracts a entities on the blockchain which can be activated when they receive certain messages/transactions. The above accounts map would actually be generalized to include a code value.
```json
{
  "0x1d3cf115e2777dd104ef0a61d0dc2ba78229b161": { "balance": 23.9238, "code": null },
  "0xaa1a6e3e6ef20068f7f8d8c835d2d22fd5116444": { "balance": 89.8932, "code": "606e80600b6000396079567c01000..." },
}
```

This is byte code for the EVM (_ethereum virtual machine_) instruction set. When a transaction is send to address `0xaa1a6e3e6ef20068f7f8d8c835d2d22fd5116444` it can also include some `input data` which might call a function that exists in this byte code. If this happens, apart from the usual transaction mechanism of increasing the receiver's balance, the some code will also be run and this may result in more transactions or calls to other contracts. You can see the code of one such contract [here](https://etherscan.io/address/0x9e82d1745c6c9c04a6cfcde102837cf0f25efc56#code).

### Miners & Gas
Miners are computers on the network that perform three primary functions (at least for now). These functions are necessary to compute and maintain the blockchain history. For this work, miners are rewarded in the form of transaction fees (debited from the sender) and the _block reward_ - free ether that is minted as specified in the protocol whenever a miner successfully mines (completes the _proof of work_ for) a block.

__Functions of a miner:__
1. They validate recently submitted transactions - if these are from external accounts they will have to check that the digital signatures are correct and authorize the sending of ethereum from account to another.
2. They will also run any computation that might result from calling a method in a contract.
3. They will complete the _proof of work_ that is required to officially make the block part of the chain. A _proof of work_ is a computational task that requires time and energy to complete. This is used as a consensus mechanism so that the network can believe on some version of transaction history.

Steps 1 & 3 are quite like bitcoin however step 2 is where the nuance of an ethereum contract is realised. The _halting problem_ of computer science is at play here since running a Turing complete scripts could result in an unknown amount of computation, potentially infinite if an infinite loop is induced. So to stop a miner essentially getting DOS'ed or expending more resources than their mining rewards are earning them, the concept of _gas_ is introduced. Every instruction that can be executed in the EVM has an associated gas cost which the miner keeps track of during execution. For example, taken from the [yellow paper](http://gavwood.com/paper.pdf), it costs 3 gas to execute the `ADD` instruction and 10 gas to execute `JUMPI`.

When a user invokes a method in a contract by sending a transaction to it, they also specify two important parameters - `STARTGAS` (aks `GASLIMIT`) and `GASPRICE`. The `STARTGAS` value is the amount of gas the sender is willing to spend on executing the desired method in the contract. `GASPRICE` is what the sender is willing to pay for each gas. So multiplying the two parameters together gives you the upper bound of the cost of calling the contract (but this cost is separate from the `VALUE` amount of the transaction which is how much you will increase the balance of the contract by). When a transaction gets submitted to the network a miner will choose if it is worth their time to _mine_ this transaction. If the `GASPRICE` is too low on your transaction and other people have submitted better deals then the miner will preferentially choose the more lucrative transactions. `GASLIMIT` is required to know how much you are willing to spend. Before the miner begins mining your transaction, they will always check if your balance has at least `GASPRICE * GASLIMIT` ether so that if they compute until your `GASLIMIT` runs out, they can be paid for that computation.

As an example, see the data in [this transaction](https://etherscan.io/tx/0x8b253799a87efd08133e4f2b7dcece785a05d6de075c92435da48cb61009ac7e) send from the address `0x26dd6b7a2fff271aa7c5fe8cfb5ba0ab33f47408` and sent to the contract at the address `0x9e82d1745c6c9c04a6cfcde102837cf0f25efc56`.
  - The `STARTGAS` (shown just as `gas`) was 9000 and the actual amount of gas used was 83845 (pretty close!). The gas price the user gave was 0.00000005 and so the cost of the contract computation was 0.00419225 ETH.
  - Cumulative gas used was actually 104845 since each transaction also has a base cost of 21000 gas.
  - _block height_ (which is 670033) means that the TX was mined in block 670033 and there are some number of block confirmations, which at the time of writing this is 1572466. This is the number of block which have been appended after this block. In blockchains, the futher something is in the past, the hard it is for a miner to rewrite that part of history and still mine enough blocks to beat the rest of the network. So each block that is mined of top of a particular transaction is called a _confirmation_ and the more confirmation you have the more certain you can be that the transaction is final. Anything beyond 60 blocks is pretty final.
  - If you go to the [`VMTrace` tab](https://etherscan.io/vmtrace?txhash=0x8b253799a87efd08133e4f2b7dcece785a05d6de075c92435da48cb61009ac7e) you can see the instructions that were executed in this contract as a result of this transaction. Also shown is the `GasCost` for each instruction and the `Gas` column is showing the amount of as left in the tank. By far the most expensive operation was the `SSTORE` which is used to store long term data in the contract.
  - The transaction had a value of 0 ETH, which means it will not increase the balance of the contract, this transaction was used purely to execute some code in the contract. In other scenarios, a transaction may just give a value and call no function (like transactions between wallets) or may both call a transaction and deposit some money with the contract.
  - There is also a nonce (9) for this transaction. Everytime an address successfully sends ETH a nonce is incremented and the next transaction must use a nonce matching the newly incremented number. It starts at 0 and so since this TX has a nonce of 9 we can infer that this is the 10th outbound transaction from [this address (which you can inspect)](https://etherscan.io/txs?a=0x26dd6b7a2fff271aa7c5fe8cfb5ba0ab33f47408). This is a security mechanism used to ensure that transactions are only processed once and cannot be replayed.

As you write your ethereum contract, you will want to make sure that you have efficient code so that as little as possible gas is required to run your functions.

### Deploying & Interacting with Contracts
Deploying a contract, which is adding an entry to the accounts map as described above, costs gas since a miner has to expend work to mine the block and since contracts are of arbitrary length, the more bytes in the code the more gas it will cost. The basic steps to deploying and then using a contract are as follows:

1. The user sets up an ethereum wallet (which means some software generates a key pair and uses the public key to generate an address).
2. The user buys ethereum from someone else (typically new ethereum is coming into existance from miners) and that ether is sent to their address.
3. The user will develop a contract, test and compile the source code into some byte code.
4. The user uses their wallet application to make a transaction that declares this contract and submits it to the blockchain. As a result of this, the contract will be given an address.
5. The user (or any user) can now use a wallet to send to the contract address and if they would like to call a function in it. Their wallet will create input data for the transaction which will specify which function to run and with what arguments. For example, a [Twitter like contract](https://github.com/yep/eth-tweet) can be found at the [address](https://etherscan.io/address/0x9e82d1745c6c9c04a6cfcde102837cf0f25efc56).
  - If you inspect the address Etherscan will show you that it was deployed in [transaction 0xd458166ead4d6d398fd0c76616d57093798e86716dd4169d2846295223768f1f](https://etherscan.io/tx/0xd458166ead4d6d398fd0c76616d57093798e86716dd4169d2846295223768f1f) that was mined in block 543637.
  - The transaction [0x8b253799a87efd08133e4f2b7dcece785a05d6de075c92435da48cb61009ac7e](https://etherscan.io/tx/0x8b253799a87efd08133e4f2b7dcece785a05d6de075c92435da48cb61009ac7e) was used to call a method on the contract and at the `Input Data` section you click `Convert to Ascii` to see the input data in a more human readable format. We can see the string `hello world` was submitted. The previous bytes `ûFÔÅ` are probably used to call a specific method.
