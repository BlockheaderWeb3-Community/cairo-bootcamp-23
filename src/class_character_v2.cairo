#[starknet::contract]
mod ClassCharacterV2 {
    use core::zeroable::Zeroable;
    use core::starknet::event::EventEmitter;
    use starknet::{ContractAddress, get_caller_address};

    // event 
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnerUpdated: OwnerUpdated,
        StudentAdded: StudentAdded
    }

    #[derive(Drop, starknet::Event)]
    struct OwnerUpdated {
        init_owner: ContractAddress,
        new_owner: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct StudentAdded {
        student: ContractAddress,
    }

    #[storage]
    struct Storage {
        owner: ContractAddress,
        students: LegacyMap::<ContractAddress, Student>
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct Student {
        name: felt252,
        age: u8,
        is_active: bool,
        has_reward: bool,
        xp_earnings: u256
    }

    #[constructor]
    fn constructor(ref self: ContractState, _init_owner: ContractAddress) {
        self.owner.write(_init_owner);
    }

    #[external(v0)]
    fn add_student(
        ref self: ContractState,
        student_account: ContractAddress,
        _name: felt252,
        _age: u8,
        _is_active: bool,
        _has_reward: bool,
        _xp_earnings: u256,
    ) {
        let owner = self.owner.read();
        let caller = get_caller_address();

        assert(owner == caller, 'caller not owner');

        assert(!student_account.is_zero(), 'is zero address');
        assert(_name != '', 'name cannot be empty');
        assert(_age != 0, 'age cannot be zero');
        assert(student_account != owner, 'not owner');
        let student_instance = Student {
            name: _name,
            age: _age,
            is_active: _is_active,
            has_reward: _has_reward,
            xp_earnings: _xp_earnings
        };
        self.students.write(student_account, student_instance);
        self.emit(StudentAdded { student: student_account });
    }
    #[external(v0)]
    fn set_owner(ref self: ContractState, _new_owner: ContractAddress) -> bool {
        let owner = self.owner.read();
        let caller = get_caller_address();
        assert(owner == caller, 'caller not owner');
        self.owner.write(_new_owner);
        self.emit(OwnerUpdated { init_owner: owner, new_owner: _new_owner });
        true
    }

    #[external(v0)]
    fn get_owner(self: @ContractState) -> ContractAddress {
        self.owner.read()
    }

    // without specifying the external attribute, this function cannot be access outside this contract
    fn internal_get_owner(self: @ContractState) -> ContractAddress {
        self.owner.read()
    }

    #[external(v0)]
    fn get_student(self: @ContractState, student_account: ContractAddress) -> Student {
        self.students.read(student_account)
    }
//  #[generate_trait] // this attribute is used to generate a trait that is not declared at compile time

}
