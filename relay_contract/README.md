# Relay Contract

Dead simple ethereum contract written in [Serpent](https://github.com/ethereum/wiki/wiki/Serpent). This contract will forward any money sent to it on to an address hard coded into the contract code. My currently live version of this contract is at [address 0x12AC1d111E6500EA6c192b1BC60cB9b48D0c7ef9](https://etherscan.io/address/0x12AC1d111E6500EA6c192b1BC60cB9b48D0c7ef9). Don't send to this one though because I would receive your ethereum :).

This lesson assumes that you have completed the [setup section](../setup.md) and will use the pyetherum simulator to verify the action of the contract.
The simulation is annotated to explain most of the state changes occurring.

## Make your own version of this contract.
Inspect the [contract code](relay_contract.se) and build your own version where the hard coded address is your own. You can use the address of the account that Mist made for you. It is a very simple contract that simply sends the ethereum contained in the transaction to the address you specify and returns a different result depending on the outcome of the `send()` method. `msg` is a global variable that lives in the environment of the contract while it executes and contains data about the message that was sent to the contract (for example the value of the tx, the address of the sender).

## Test Locally In [Pyethereum](https://github.com/ethereum/pyethereum/wiki/Using-pyethereum.tester) Simulator
```bash
### open python terminal and set up environment
$ python # either locally or in docker container
```
```python
>>> import ethereum.tester as t
>>> s = t.state()
>>> s.block.number
0 # we are starting at the genesis block

### initialise some useful constants
# Our destination address 0x3b2097eE1B3cCcE5ffaFB43fA16042dE7EDB54Ee - something I controll
>>> dest_address = b'\x3b\x20\x97\xeE\x1B\x3c\xCc\xE5\xff\xaF\xB4\x3f\xA1\x60\x42\xdE\x7E\xDB\x54\xEe'

# Address of some user who will send to the contract.
# The simulator just comes with a bunch of prebuild addresses and balances.
>>> user_addr = t.accounts[1]
>>> user_key  = t.keys[1]

# To better understand the flow (and conservation) of ethereum we
# will set and inspect the miner's balance.
>>> miner_addr = t.accounts[2]
>>> miner_addr
b'\xdc\xec\xea\xf3\xfc\\\nc\xd1\x95\xd6\x9b\x1a\x90\x01\x1b{\x19e\r'

# Can ignore this for now, but we are just mining a few blocks
# into the future to make things cleaner.
>>> s.mine(10, coinbase=miner_addr)
>>> s.block.number
10

### check the state of interesting variables
# note that this is in wei (10E18 wei = 1 ether)
>>> s.block.get_balance(dest_address)
0
>>> s.block.get_balance(user_addr)
1000000000000000000000000 # 1 million ether
>>> s.block.get_balance(miner_addr)
1000045000000000000000000 # 1.000045 million ether

### deploy contract from user 5 - this uses gas.
# We will inspect the balance of user 5 before and after to see the effet.
>>> deployer_address = t.accounts[5]
>>> deployer_key = t.keys[5]
>>> balance_before_deploy = s.block.get_balance(deployer_address)
>>> s.block.gas_used # 0
>>> contract = s.abi_contract('relay_contract.se', sender=deployer_key)
>>> gas_used_from_deploy = s.block.gas_used # 49186
>>> balance_after_deploy = s.block.get_balance(deployer_address) # 999999999999999999950814L

>>> balance_after_deploy + gas_used_from_deploy
1000000000000000000000000L # which is balance_before_deploy

# when a contract is deployed, it is granted an address with a balance
>>> s.block.get_balance(contract.address)
0 # as expected, this contract does not hold a balance (and never will)

# The gas that was spent by the deployer had to go somewhere.
# Miner earnt the 49186 wei since deploying the contract required computational work.
>>> s.block.get_balance(miner_addr)
1000045000000000000049186

# Notice they have not received the block reward yet.
# A block reward for a block just mined will come in the next block.

### go forward 1 block
# The "coinbase" is the address of the miner and this is where
# the block reward and mining fees will go.
>>> s.mine(1, coinbase=miner_addr)
>>> s.block.get_balance(miner_addr)
1000050000000000000049186
# The miner now has the block reward of 5 ETH.
# 5 ETH happens to also be the block reward at this point in time.

### call the contract
>>> contract.relay(value=1000000, sender=user_key)
1 # success

>>> s.block.get_balance(dest_address)
1000000 # as expected, now we have 1000000 at dest_addr
>>> s.block.get_balance(user_addr)
999999999999999998946882 # 1M ETH - 1000000 wei (message value) - 53118 wei (gas)
>>> s.block.gas_used
53118 # the gas used to call this contract
>>> s.block.get_balance(miner_addr)
1000050000000000000102304 # +53118 wei from gas

>>> t.gas_price
1
# gas_used * gas_price = fees that the miner gets

>>> exit() # fine...
```

#### Some notes on this simulation
  - Why was `get_balance()` chained off of the `block` object? Each block in Ethereum attempts to change the state of a data structure (known as the [Merkle Patricia Tree](https://github.com/ethereum/wiki/wiki/Patricia-Tree)) which stores account balances. `s.block` represents the state of this data structure at the current time.
  - Why were gas fees awarded immediately after an action (really it would be when the block is mined) while block rewards only show in the miner's balance after the next block is mined? _My guess_, is that since rewards are also given to miners who submit _uncle blocks_ (block that are published soon after the first mined block and have a valid proof of work), the block rewards have to be given one block later. The miner who submits a block does know how much they have collected in gas fees but they do not know about other uncle blocks. To make it clean I assume that uncle & the full block reward are just issued all at the same time in the next block.


## Compile & Deploy
Compile the contract either natively or in the Docker container.
```bash
serpent compile relay_contract.se # generates what is in contract_byte_code.txt
```

We can now use Mist to deploy this byte code. Start Mist in test net mode and grab some ether from the faucet (explained in the [setup doc](../setup.md)). Find the `contracts` button, click `deploy contract` and toggle to the `contract byte code` pane. Here you can paste the byte code. You don't need to enter an amount since this contract does not need a balance (that would just be wasted and unmovable ethereum). The `select fee` slider is autoconfigured by Mist to be competitive for the mining market so you wont need to change that. Click deploy, the transaction will get mined within 30 seconds and then you will have an address where you contract exists.

## Try the contract
```bash
serpent mk_full_signature relay_contract.se
[{"type": "function", "constant": false, "name": "relay()", "outputs": [{"type": "int256", "name": "out"}], "inputs": []}]
```
The string printed out above is called the contract's _ABI_ (_Application Binary Interface_) which is used to tell a client wallet how to interact with the transaction. Go back to the `contracts page`, click the `watch contract button`. This will open up a form where you can enter to address of the contract, the ABI and give it a name of your choosing.

A SUPER nasty bug is here though. If you import that ABI into Mist, it will fail when you send to the contract and that is because the ABI spec was updated and `serpent` is still on the old version (at least at the time of writing this). To fix it, the parenthesis after `relay` should be removed.

Now when you go to the contract page in Mist, scroll down and use the `Pick a Function` dropdown. Select `relay`, enter a value _et voilà_. You can use a block explorer to then view the transaction you just made and the one that the contact will make. Here is [my example contract](https://etherscan.io/address/0x12AC1d111E6500EA6c192b1BC60cB9b48D0c7ef9) on the main net. [TX 0x806acb0a5058414d3378619851352f74d68c492fcca3933267a0108b1c4a395a](https://etherscan.io/tx/0x806acb0a5058414d3378619851352f74d68c492fcca3933267a0108b1c4a395a) is me sending to it from Mist and if you look at the `To` section or the `Internal Transactions` tab you will see the transaction that the contract made to the destination address. Since contracts actually create _messages_ (rather than _transactions_) to move ethereum, there is no official transaction view for this action.
