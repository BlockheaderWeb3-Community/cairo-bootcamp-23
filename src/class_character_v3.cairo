use starknet::ContractAddress;
#[starknet::interface]
trait IStudent<TContractState> {
    fn add_student(
        ref self: TContractState,
        student_account: ContractAddress,
        _name: felt252,
        _age: u8,
        _is_active: bool,
        _has_reward: bool,
        _xp_earnings: u256,
    );

    fn get_student(self: @TContractState) -> ContractAddress;
}

#[starknet::interface]
trait IStudentWithAccess<TContractState> {
    fn add_student(
        ref self: TContractState,
        student_account: ContractAddress,
        _name: felt252,
        _age: u8,
        _is_active: bool,
        _has_reward: bool,
        _xp_earnings: u256,
    );

    fn get_student(self: @TContractState) -> ContractAddress;
}


#[starknet::interface]
trait IOwnable<TContractState> {
    fn set_owner(ref self: ContractState, new_owner: ContractAddress);

    fn get_owner(self: ContractState) -> ContractAddress;
}

#[starknet::interface]
trait IOwnableWithAccess<TContractState> {
    fn set_owner(ref self: ContractState, new_owner: ContractAddress);

    fn get_owner(self: ContractState) -> ContractAddress;
}


#[starknet::contract]
mod ClassCharacterV3 {
    use super::{IOwnable, IOwnableWithAccessControl};
    use super::{IStudent, IStudentWithAccess};
    use core::zeroable::Zeroable;
    use core::starknet::event::EventEmitter;
    use starknet::{ContractAddress, get_caller_address};

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

    #[constructor]
    fn constructor(ref self: ContractState, init_owner: ContractAddress) {
        self.owner.write(init_owner);
    }

    #[derive(Copy, Drop, Serde, starknet::Store)]
    struct Student {
        name: felt252,
        age: u8,
        is_active: bool,
        has_reward: bool,
        xp_earnings: u256
    }

    #[abi_embed(v0)]
    impl StudentImpl of IStudent<ContractState> {
        fn add_student(
            ref self: TContractState,
            student_account: ContractAddress,
            _name: felt252,
            _age: u8,
            _is_active: bool,
            _has_reward: bool,
            _xp_earnings: u256,
        ) {
            assert(!student_account.is_zero(), 'caller cannot be address zero');
            assert(student_account != owner, 'student_account cannot be owner');
            assert(_name != '', 'name cannot be empty');
            assert(_age != 0, 'age cannot be zero');

            // Create student instance
            let student_instance = Student { _name, _age, is_active, _has_reward, _xp_earnings };
            self.students.write(student_account, student_instance);
            self.emit(StudentAdded { Student: student_account });
        }

        fn get_student(self: @TContractState) -> ContractAddress {
            self.only_owner();
            self.students.read();
        }
    }

    #[abi_embed(v0)]
    impl StudentImplWithoutAcess of IStudent<ContractState> {
        fn add_student(
            ref self: TContractState,
            student_account: ContractAddress,
            _name: felt252,
            _age: u8,
            _is_active: bool,
            _has_reward: bool,
            _xp_earnings: u256,
        ) {
            self.only_owner();
            assert(!student_account.is_zero(), 'caller cannot be address zero');
            assert(student_account != owner, 'student_account cannot be owner');
            assert(_name != '', 'name cannot be empty');
            assert(_age != 0, 'age cannot be zero');

            // Create student instance
            let student_instance = Student { _name, _age, is_active, _has_reward, _xp_earnings };
            self.students.write(student_account, student_instance);
            self.emit(StudentAdded { Student: student_account });
        }

        fn get_student(self: @TContractState) -> ContractAddress {
            self.only_owner();
            self.students.read();
        }
    }


    #[abi_embed(v0)]
    impl OwnableImpl of IOwnable<ContractState> {
        fn set_owner(ref self: ContractState, new_owner: ContractAddress) {
            self.owner.write(new_owner);
            self.emit(OwnerUpdated { init_owner: owner, new_owner: new_owner });
            true
        }

        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read();
        }
    }

    impl OwnableWithAccessImpl of IOwnable<ContractState> {
        fn set_owner(ref self: ContractState, new_owner: ContractAddress) {
            self.only_owner();
            self.owner.write(new_owner);
            self.emit(OwnerUpdated { init_owner: owner, new_owner: new_owner });
            true
        }

        fn get_owner(self: @ContractState) -> ContractAddress {
            self.only_owner();
            self.owner.read();
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
