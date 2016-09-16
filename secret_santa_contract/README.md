# Secret Santa Contract

This contract is special because you cannot build this application in traditional webapp style, you need ethereum.

The contract has two functions:
  - `register()`: If a user gives above the minimum registration fee, they are recorded into a set of user. The money they sent when invoking register is then credited (not sent) to a random user in the set of registered users.
  - `withdraw_balance()`: Sends a user their balance if they have one.

You cannot build this application if you are some random developer. You can standup a website, but no on is going to believe that you will actually forward the money on to someone - it would be a ponzi scheme. The only groups that could run this website is a bank or some company which has incorporated, has lawyers and contracts. This is a huge barrier to entry. With ethereum, anyone can program how someones money moves and their users will have no trouble trusting them. This is a revolution in finance.

### If you like to use the secret santa contract, copy the [contract ABI](contract_abi.json) into Mist and you can use it at these addresses:
  - Main net: `0x37597770DBc5A75E86726455048398532E269278`
  - Test net: ...

## Simulation
```python
>>> import ethereum.tester as t
>>> s = t.state()

# we will user 3 users (2,3,4) (including the one to deploy the contract)
>>> contract = s.abi_contract('relay_contract.se', sender=t.keys[2])

# too little ethereum in the transaction value
>>> contract.register(value=100, sender=t.keys[3])
1 # exit code for REGISTRATION_FEE_TOO_LOW

# two user now send over the threshold
>>> contract.register(value=100000000000000000, sender=t.keys[3]) # 0.1 ETH
0 # success
>>> contract.register(value=100000000000000000, sender=t.keys[4]) # 0.1 ETH
0 # success
# since we did not mine forward a block here, the lucky use is the same each time.

# try a definitely fraudelent withdrawal
>>> contract.withdraw_balance(sender=t.keys[5])
2 # exit code for NO_BALANCE_ERROR

# try real withdrawls, but first check balances
>>> s.block.get_balance(t.accounts[2])
999999999999999999756816L
>>> s.block.get_balance(t.accounts[3])
999999999999999999756816L
>>> s.block.get_balance(t.accounts[4])
999999899999999999890616L

contract.withdraw_balance(sender=t.keys[2])
0 # success
>>> s.block.get_balance(t.accounts[2])
1000000199999999999738046L

# we see the balance has gone up by 0.2 ETH (minus gas)
1000000199999999999738046L - 100000000000000000 - 100000000000000000
999999999999999999738046L # which is pretty close to 999999999999999999756816L above

# verify this user can no longer withdraw funds (balance back to 0)
>>> contract.withdraw_balance(sender=t.keys[2])
2

# since user at index 2 got the ether, the others should get no balance errors
>>> contract.withdraw_balance(sender=t.keys[3])
2
>>> contract.withdraw_balance(sender=t.keys[4])
2

# mine forward and check someone else (hopefully) gets picked
s.mine(1)
>>> contract.register(value=100000000000000000, sender=t.keys[3])
0 # success

>>> s.block.get_balance(t.accounts[3])
prev_balance = 999999799999999999765445L

>>> contract.withdraw_balance(sender=t.keys[2])
2 # nope
>>> contract.withdraw_balance(sender=t.keys[3])
0 # the lucky one (they actually sent to themselves lol)
>>> contract.withdraw_balance(sender=t.keys[4])
2 # nope

>>> s.block.get_balance(t.accounts[3])
curr_balance = 999999899999999999746675L
>>> curr_balance - prev_balance
99999999999981230L # 0.1 ETH - gas used to execute the withdraw method
```

## Gotchas
There is probably an infinite list of things that could go here. But while I was writing this contract, this is what cost me time:
  - Everything that a compiler would normally catch (undefined variables, mismatching types, etc) is not caught by the simulator or the compiler. You need to be extremely sure of the code and the quick hacky way to debug things is to simply `return()` the values you want to inspect and then invoke the method. Common mistake is spelling or to not include `self` for long term data.
  - A lot of uninitialised data is simply 0. Or mismatched types used with an operator might just yeild 0.
  - Data types are interpreted in strange ways. The block hash is a large unsigned integer in theory, but when you do arithmetic on it it might be interpreted as a signed in. For instance, `block.prevhash % 2` will provide the following results.
  - Not returning from a function is undefined behaviour.

```python
# mine before each call to get a new blockhash each time
>>> s.mine(1); contract.register(value=100000000, sender=t.keys[1])
0
>>> s.mine(1); contract.register(value=100000000, sender=t.keys[1])
1
>>> s.mine(1); contract.register(value=100000000, sender=t.keys[1])
-1L
```
## Notes
  - We have a separate method for withdrawing funds as this is a security best practice. You want this function to be very simple, robust and not tarnished by other application logic/state. Remember that if you have a bug in a deployed contract, it will be there forever since there is no way to update the code!
  - Using `block.prevhash` as a source of random entry is only _ok_. For real contracts where this matters you should research the latest thoughts on this in the community. The threat here is that given a single block's worth of entropy, the miner is able to influence the value a little bit. Especially if you take the module of the block hash and condense the range into just a few bits of key space, a little influence (like just the option to include a transaction or not) can have a large difference. Once idea to mitigate against this threat is to access some number of block hashes in the past (a contract has access to the last 256 block hashes) and xor them together to get a seed.

# change in other contract
c = s.abi_contract(code, language='solidity', sender=t.k0)
