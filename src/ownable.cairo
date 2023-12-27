use starknet::ContractAddress;
#[starknet::interface]
trait IOwnable<T> {
    fn set_owner(ref self: T, addr: ContractAddress) -> bool;
    fn get_owner(self: @T) -> ContractAddress;
}

// custom error for handling validation logic
mod Errors {
    const ZERO_ADDR: felt252 = '0_ADDR: detected';
}

#[starknet::contract]
mod Ownable {
    use super::{IOwnable, Errors};
    use starknet::ContractAddress;
    use core::Zeroable;

    #[storage]
    struct Storage {
        owner: ContractAddress
    }


    #[external(v0)]
    // impl logic of IOwnable trait
    impl IOwnableImpl of IOwnable<ContractState> {
        fn set_owner(ref self: ContractState, addr: ContractAddress) -> bool {
            assert(!addr.is_zero(), Errors::ZERO_ADDR);
            self.owner.write(addr);
            true
        }
        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }
    }
}
