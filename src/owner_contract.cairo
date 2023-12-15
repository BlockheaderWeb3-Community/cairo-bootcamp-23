#[starknet::interface]
// trait definition
trait IOwnable<T> {
    fn set_owner(ref self: T, new_owner: ContractAddress);
    fn get_owner(self: @T) -> ContractAddress;
}

#[starknet::contract]
mod OwnerContract {
    #[storage]
    struct Storage {
        owner: ContractAddress,
    }

    #[abi_embed(v0)]
    // #[external(v0)]
    impl OwnableImpl of IOwnable<ContractState> {
        fn set_owner(ref self: ContractState, new_owner: ContractAddress) {
            self.owner.write(new_owner);
        }
        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn set_owner_OnlyOwner(ref sef: ContractState, new_owner: ContractAddress) {
            // let caller = get_caller_address();
            // let owner = self.owner.read();
            // assert(caller == owner, 'Caller is not the owner');
            self.only_owner();
            self.owner.write(new_owner);
        }

        fn get_owner_onlyOwner(self: @ContractState) -> ContractAddress {
            // let caller = get_caller_address();
            // assert(caller == owner, 'Caller is not the owner');
            self.only_owner();
            self.owner.read()
        }
    }

    #[generate_trait]
    impl PrivateMethods of PrivateMethodsTrait {
        fn only_owner(self: @ContractState) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'Caller is not the owner');
        }
    }
}
