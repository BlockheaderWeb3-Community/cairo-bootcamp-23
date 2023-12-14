# Introduction to Starknet Contracts
1. Install starknet-foundry by running this command:
`curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh`
restart your terminal
run `foundryup`

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
