// =============================================
// ========= TRIATS ============================
// trait definition
use starknet::{ContractAddress};
#[starknet::interface]
trait IClassCharacter<T> {
    fn set_owner(ref self: T, new_owner: ContractAddress) -> bool;
    fn get_owner(self: @T) -> ContractAddress;
    fn set_student(
        ref self: T,
        _studentAddr: ContractAddress,
        _name: felt252,
        _age: u8,
        _is_active: bool,
        _has_reward: bool,
        _xp_earnings: u256
    ) -> bool;
    fn get_student(self: @T, studentAddr: ContractAddress) -> Student;
}

// triat with access control
#[starknet::interface]
trait IClassCharacterWithAccessControl<T> {
    fn set_owner_with_access_control(ref self: T, new_owner: ContractAddress) -> bool;
    fn get_owner_with_access_control(self: @T) -> ContractAddress;
    fn set_student_with_access_control(
        ref self: T,
        _studentAddr: ContractAddress,
        _name: felt252,
        _age: u8,
        _is_active: bool,
        _has_reward: bool,
        _xp_earnings: u256
    ) -> bool;
    fn get_student_with_access_control(self: @T, student_addr: ContractAddress) -> Student;
}

// ==============================================
// ======= Global vars ==========================
// student struct
#[derive(Copy, Drop, Serde, starknet::Store)]
struct Student {
    name: felt252,
    age: u8,
    is_active: bool,
    has_reward: bool,
    xp_earnings: u256
}


// ================================================
// ========== SMART CONTRACT ======================

// classCharacterV3 smart contract
#[starknet::contract]
mod ClassCharacterV3 {
    // libraries and trait imports
    use core::zeroable::Zeroable;
    use starknet::{ContractAddress, get_caller_address};
    use super::{IClassCharacter, IClassCharacterWithAccessControl, Student};

    // ================================================
    // ================ CONSTRUCTOR ===================
    #[constructor]
    fn constructor(ref self: ContractState, _init_owner: ContractAddress) {
        self.owner.write(_init_owner);
    }

    // =================================================
    // ============ ERRORS =============================
    mod Errors {
        const ZERO_ADDRESS_ERROR: felt252 = 'cant be called by address zero';
        const ONLY_OWNER_ERROR: felt252 = 'Only owner allowed';
        const ONLY_ACCOUNT_OWNER: felt252 = 'Only ACCT owner allowed';
    }

    // storage 
    #[storage]
    struct Storage {
        owner: ContractAddress,
        students: LegacyMap::<ContractAddress, Student>
    }

    //===========================================
    // ======= IMPLEMENTATIONS ================== 
    // triat without access control implementation 
    #[external(v0)]
    impl classCharacterv3 of IClassCharacter<ContractState> {
        fn get_owner(self: @ContractState) -> ContractAddress {
            self.owner.read()
        }

        fn set_owner(ref self: ContractState, new_owner: ContractAddress) -> bool {
            self.owner.write(new_owner);
            true
        }

        fn get_student(self: @ContractState, studentAddr: ContractAddress) -> Student {
            self.students.read(studentAddr)
        }

        fn set_student(
            ref self: ContractState,
            _studentAddr: ContractAddress,
            _name: felt252,
            _age: u8,
            _is_active: bool,
            _has_reward: bool,
            _xp_earnings: u256
        ) -> bool {
            let student_instance = Student {
                name: _name,
                age: _age,
                is_active: _is_active,
                has_reward: _has_reward,
                xp_earnings: _xp_earnings
            };

            self.students.write(_studentAddr, student_instance);
            true
        }
    }

    // triat with access control implementation 
    #[external(v0)]
    impl classCharacterv3WithAccessControl of IClassCharacterWithAccessControl<ContractState> {
        fn get_owner_with_access_control(self: @ContractState) -> ContractAddress {
            self.zero_address();
            self.owner.read()
        }

        fn set_owner_with_access_control(
            ref self: ContractState, new_owner: ContractAddress
        ) -> bool {
            self.zero_address();
            self.only_owner();
            self.owner.write(new_owner);
            true
        }

        fn get_student_with_access_control(
            self: @ContractState, student_addr: ContractAddress
        ) -> Student {
            self.caller_is_student(student_addr);
            self.students.read(student_addr)
        }

        fn set_student_with_access_control(
            ref self: ContractState,
            _studentAddr: ContractAddress,
            _name: felt252,
            _age: u8,
            _is_active: bool,
            _has_reward: bool,
            _xp_earnings: u256
        ) -> bool {
            let student_instance = Student {
                name: _name,
                age: _age,
                is_active: _is_active,
                has_reward: _has_reward,
                xp_earnings: _xp_earnings
            };
            self.only_owner();
            self.students.write(_studentAddr, student_instance);
            true
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn only_owner(self: @ContractState) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert(caller == owner, Errors::ONLY_OWNER_ERROR)
        }

        fn zero_address(self: @ContractState) {
            let caller = get_caller_address();
            assert(!caller.is_zero(), Errors::ZERO_ADDRESS_ERROR)
        }

        fn caller_is_student(self: @ContractState, studentAddr: ContractAddress) {
            let caller = get_caller_address();
            assert(caller == studentAddr, Errors::ONLY_ACCOUNT_OWNER)
        }
    }
}
