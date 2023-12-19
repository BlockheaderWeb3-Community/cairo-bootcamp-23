use starknet::{ContractAddress};
#[starknet::interface]

//  traits automatically generate dispatchers which can be used to call other contracts
trait ICounter<T> {
    fn set_count(ref self: T, amount: u256) -> bool;
    fn get_count(self: @T) -> u256;
}

// custom error
mod Errors {
    const ZERO_ADDR: felt252 = 'ADDR_0: detected';
    const ZERO_AMT: felt252 = 'AMT_0: detected';
}

#[starknet::contract]
mod Counter {
    use class_character::ownable::{ IOwnableDispatcher, IOwnableDispatcherTrait }; // we have access to IOwnableDispatcher from Ownable contract
    use core::Zeroable;
    use super::{Errors, ICounter};
    use starknet::{ContractAddress, get_caller_address};
    #[storage]
    struct Storage {
        count: u256
    }

    #[constructor]
    fn constructor(ref self: ContractState, amount: u256) {
        self.count.write(self.count.read() + amount);
    }

    #[external(v0)]
    impl CounterImpl of ICounter<ContractState> {
        fn set_count(ref self: ContractState, amount: u256) -> bool {
            assert(amount != 0, Errors::ZERO_AMT);
            self.count.write(self.count.read() + amount);
            true
        }
        fn get_count(self: @ContractState) -> u256 {
            self.count.read()
        }
    }


    #[external(v0)]
    #[generate_trait]
    impl TestOwnableImpl of TestOwnableTrait {
        fn set_ownable_owner(ref self: ContractState, addr: ContractAddress) -> bool {
            assert(!addr.is_zero(), Errors::ZERO_ADDR);
            IOwnableDispatcher { contract_address: addr }.set_owner(addr); // we can call the set_owner function of the Ownable contract
            true
        }

        fn get_ownable_owner(self: @ContractState, addr: ContractAddress) -> ContractAddress {
            IOwnableDispatcher { contract_address: addr }.get_owner() // we can call the get_owner function of the Ownable contract
        }
    }
}
