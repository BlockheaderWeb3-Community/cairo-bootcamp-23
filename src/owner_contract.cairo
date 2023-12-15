// trait definition
use starknet::ContractAddress;
#[starknet::interface]
trait IOwnable<T> {
    fn set_owner(ref self: T, new_owner: ContractAddress);
    fn get_owner(self: @T) -> ContractAddress;
}


#[starknet::contract]
mod OwnerContract {
    use starknet::ContractAddress;
    use super::{IOwnable};

    #[storage]
    struct Storage {
        owner: ContractAddress,
    }

    #[external(v0)]
    // implementation of IOwnable trait
    impl OwnableImpl of IOwnable<ContractState> {
        fn set_owner(ref self: ContractState, new_owner: ContractAddress) {
            self.owner.write(new_owner);
        }
        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }
    }

}
