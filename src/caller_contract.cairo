#[starknet::contract]
// this caller caller will reference 2 contracts:
//  - Ownable 
//  - Counter

// Using the generated dispatchers, we would call the logic of both contracts inside this CallerContract
// Currently, this contract has no state; we are interacting with the functions of Ownable and Counter contracts within the UtilsTraitImpl implementation logic
mod CallerContract {
    use class_character::{
        counter::{ICounterDispatcher, ICounterDispatcherTrait},
        ownable::{IOwnableDispatcher, IOwnableDispatcherTrait}
    };

    use starknet::{ContractAddress};


    #[storage]
    struct Storage {}

    #[external(v0)]
    #[generate_trait]
    impl UtilsTraitImpl of UtilsTrait {
        // <<<<OWNABLE FUNCTIONS>>>>
        // call Ownable contract's get_owner function
        fn get_ownable_owner(
            self: @ContractState, ownable_addr: ContractAddress
        ) -> ContractAddress {
            // here we are passing the contract address of Ownable contract into  IOwnableDispatcher
            // then we call the get owner function
            IOwnableDispatcher { contract_address: ownable_addr }.get_owner()
        }

        // invoke Ownable contract's set_owner function
        fn set_ownable_owner(
            ref self: ContractState, ownable_addr: ContractAddress, new_owner: ContractAddress
        ) -> bool {
            // here we are passing the contract address of Ownable contract into  IOwnableDispatcher
            // then we invoke the set_owner function with the new_owner arg
            IOwnableDispatcher { contract_address: ownable_addr }.set_owner(new_owner);
            true
        }

        // <<<<COUNTER FUNCTIONS>>>>
        // call Counter contract's get_count function
        fn get_current_count(self: @ContractState, counter_addr: ContractAddress) -> bool {
            // here we are passing the contract address of Counter contract into ICounterDispatcher 
            // then we call the get_count function w/o any arg
            ICounterDispatcher { contract_address: counter_addr }.get_count();
            true
        }

        // invoke Counter contract's increase_count function
        fn increment(ref self: ContractState, counter_addr: ContractAddress, amount: u256) -> bool {
            // here we are passing the contract address of Counter contract into  ICounterDispatcher 
            // then we invoke the increase_count function with the amount arg
            ICounterDispatcher { contract_address: counter_addr }.increase_count(amount);
            true
        }

        // invoke Counter contract's decrease_count function
        fn decrement(ref self: ContractState, counter_addr: ContractAddress, amount: u256) -> bool {
            // here we are passing the contract address of Counter contract into  ICounterDispatcher 
            // then we invoke the decrease_count function with the amount arg
            ICounterDispatcher { contract_address: counter_addr }.decrease_count(amount);
            true
        }
    }
}
