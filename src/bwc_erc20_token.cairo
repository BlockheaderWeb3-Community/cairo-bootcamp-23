#[starknet::contract]

// minimalistic implementation of ERC20 token 
mod BWCERC20Token {
    use starknet::{ContractAddress};
    #[storage]
    struct Storage {
        name: felt252,
        symbols: felt252,
        decimals: u256, 
        allowances: LegacyMap::<(ContractAddress, ContractAddress), u256>, 
        balances: LegacyMap::<ContractAddress, u256>
    }


}