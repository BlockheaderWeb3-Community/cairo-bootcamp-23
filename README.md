# Introduction to Testing Starknet Contract

- <a href="/tests">Test suite</a>, unit tests are provided under the each contract's implementations directly whereas full flow integration tests lies within this test suite. We use starknet-foundry testing framework in this class and test thoroughly for any edge cases in each of the contract.

## Running Tests

1. Install starknet-foundry by running this command:
`curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh`
restart your terminal
run `snfoundryup`

- To run the test suite, run `snforge test` from the root of the project directory. This will run all the tests in the test suite as well as the unit tests in the contracts' file.


