// trait definition
use starknet::ContractAddress;
#[starknet::interface]
trait IOwnable<T> {
    fn set_owner(ref self: T, new_owner: ContractAddress);
    fn get_owner(self: @T) -> ContractAddress;
}

#[starknet::interface]
trait IOwnableWithAccessControl<T> {
    fn set_owner_with_access_control(ref self: T, new_owner: ContractAddress);
    fn get_owner_with_access_control(self: @T) -> ContractAddress;
}


#[starknet::contract]
mod OwnerContract {
    use starknet::{ContractAddress, get_caller_address};
    use super::{IOwnable, IOwnableWithAccessControl};

    #[storage]
    struct Storage {
        owner: ContractAddress,
    }

    // implementation of IOwnable trait
    #[external(v0)]
    impl OwnableImpl of IOwnable<ContractState> {
        fn set_owner(ref self: ContractState, new_owner: ContractAddress) {
            self.owner.write(new_owner);
        }
        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }
    }

    // implementation of IOwnableWithAccessControl trait
    #[external(v0)]
    impl OwnableWithAccessControlImpl of IOwnableWithAccessControl<ContractState> {
        fn set_owner_with_access_control(ref self: ContractState, new_owner: ContractAddress) {
            self.only_owner();
            self.owner.write(new_owner);
        }
        fn get_owner_with_access_control(self: @ContractState) -> ContractAddress {
            self.only_owner();
            self.owner.read()
        }
    }

    #[generate_trait] // this attribute is used to write impl directly w/o creating a trait
    impl Private of PrivateTrait {
        fn only_owner(self: @ContractState) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert(caller == owner, 'caller not owner')
        }
    }
}
