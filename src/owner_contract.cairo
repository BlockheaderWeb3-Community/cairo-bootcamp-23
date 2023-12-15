#[starknet::interface]

// trait definition
trait IOwnable <T> {
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
    impl OwnableImpl of IOwnable <ContractState>{
        fn set_owner(ref self: ContractState, new_owner: ContractAddress) {
            self.owner.write(new_owner);

        }
    fn get_owner(self: @ContractState) -> ContractAddress {
        self.owner.read()
    }

    fn assert_only_owner(self: @ContractState) {
            let owner: ContractAddress = self.owner.read();
            let caller = get_caller_address();
            assert(caller == owner, 'Caller is not the owner');
        }

        
    }

}