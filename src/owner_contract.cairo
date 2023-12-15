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
        // No Access control check

        fn set_ownerr(ref self: ContractState, new_owner: ContractAddress) {
            self.owner.write(new_owner);
        }

        // Access control check
        fn set_owner(ref self: ContractState, new_owner: ContractAddress) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert(caller == owner, 'caller is not owner');
            self.owner.write(new_owner);
        }

        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }
    }
}
