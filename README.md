# Introduction to Starknet Contracts
1. Install starknet-foundry by running this command:
`curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh`
restart your terminal
run `snfoundryup`

2. Create an account on any of these RPC provides:
    - [Voyager](https://voyager.online/)
    - [BlastAPI](https://starknet-testnet.blastapi.io)
    - [Infura](https://www.infura.io/)

Generate an RPC apikey to interact with the network

3. Create a contract account by running this command on your terminal:
`sncast -u <rpc-url> account create -n <name> --add-profile`

4. Deploy the contract account:
`sncast --url <rpc_url_with_api_key> account deploy --name <account_name> --max-fee 4323000047553`
`NB`
Running the above command should trigger an error: 
`error: Account balance is smaller than the transaction's max_fee.`
That why your account must be funded; to fund your account, visit - https://faucet.goerli.starknet.io/ 

5. Compile your contract by running: `scarb build`

6. Declare your contract:
`sncast --account test_deploy -u <url> declare --contract-name <contract_name>`

7. Deploy your contract:
`sncast  --account <your_account> --url <your_rpc_url> deploy  --class-hash <generated_class_hash>`

`NB`
While deploying, make sure you check the constructor argument of the contract you are trying to deploy. All arguments must be passed in appropriately; for such case, use this command:
```sncast  --account <your_account_name> --url <your_rpc_url> deploy  --class-hash <your_class_hash>  --constructor-calldata <your_constructor_args>```




---
# Introduction to Dispatchers


### Deployed Contracts

#### Ownable Contract
- [x] class hash - 0x421a3ad93deda96f863e26ab51a79f4cea384d71714a5b37ace35010872a088
- [x] address - 0x4a742edef4df3d3fb09809535a322971ababb1f337ffcf5c297a941f54a76e1

#### Counter Contract
- [x] class hash - 0x71d83bb407cdd1a963bdcba92c82b3ff18e8e56fd3cfa9410b0dce069477511
- [x] address - 0x14b32ec4783dabf825bb2ff4c82b20a81273455cf90ff263c85216b54b1f36d

#### Caller Contract
- [x] class hash - 0x6c9d24030d72669af3e857dc1f04981c5cf316e0c2efee443509bbf95530587
- [x] address - 0x2ee3772f1ec48d45bd6280daf74bc35eacd8f5dd741daceaea04130bade808



--- 
### Interacting with Deployed Contracts
- Invoke: to execute the logic of a state-changing (writes) function within your deployed contracts from the terminal, run
```
sncast --url <your_rpc_url>  --account <account_name> invoke --contract-address <your_contract_address> --function "<your_function_name>" --calldata <fn_args>
```


- Call: to execute the logic of a non-state-changing (reads) function within your deployed contracts from the terminal, run:
```
sncast --url <your_rpc_url>  --account <account_name> call --contract-address <your_contract_address> --function "<your_function_name"
```

`NB`:

- To test out dispatchers, please call the address the `CallerContract` which contains dispatchers to call the logic of `Ownable` and `Counter` contracts respectively
- In the event the function to be called accepts some args, append the call `--calldata` flag to the above `invoke` and `call` commands with the appropriate `args`


