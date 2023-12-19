use starknet::{ContractAddress};
#[starknet::interface]
trait IOwnable<T> {
    fn set_owner(ref self: T, addr: ContractAddress) -> bool;
    fn get_owner(self: @T) -> ContractAddress;
}

mod Errors {
    const ZERO_ADDR: felt252 = 'ADDR_0: detected';
}

#[starknet::contract]
mod Ownable {
    use core::Zeroable;
    use super::{Errors, IOwnable};
    use starknet::{ContractAddress, get_caller_address};
    #[storage]
    struct Storage {
        owner: ContractAddress
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.owner.write(get_caller_address());
    }


    #[external(v0)]
    // #[abi(embed_v0)]
    impl OwnableImpl of IOwnable<ContractState> {
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
