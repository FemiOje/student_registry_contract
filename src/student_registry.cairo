use student_registry_contract::student_struct::Student;

#[starknet::interface]
pub trait IStudentRegistry<T> {
    // state-change function to add new studen
    fn add_student(
        ref self: T,
        fname: felt252,
        lname: felt252,
        phone_number: felt252,
        age: u8,
        is_active: bool,
    ) -> bool;

    // read-only function to get student
    fn get_student(self: @T, index: u64) -> (felt252, felt252, felt252, u8, bool);
    fn get_all_students(self: @T) -> Span<Student>;
    fn update_student(
        ref self: T, index: u64, fname: felt252, lname: felt252, phone_number: felt252, age: u8,
    ) -> bool;
    fn delete_student(ref self: T, _index: u64) -> bool;
}


#[starknet::contract]
pub mod StudentRegistry {
    use core::num::traits::Zero;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_upgrades::UpgradeableComponent;
    use openzeppelin_upgrades::interface::IUpgradeable;
    use starknet::{ContractAddress};
    use starknet::ClassHash;
    use super::{IStudentRegistry, Student};


    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map,
    };
    use student_registry_contract::errors::Errors;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        admin: ContractAddress,
        students_map: Map::<u64, Student>,
        students_index: Map::<u64, ContractAddress>,
        total_no_of_students: u64,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, _admin: ContractAddress) {
        // validation to check if admin account has valid address and not 0 address
        assert(!self.is_zero_address(_admin), Errors::ZERO_ADDRESS);
        self.admin.write(_admin);
        self.ownable.initializer(_admin);
    }

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    #[abi(embed_v0)]
    impl StudentRegistryImpl of IStudentRegistry<ContractState> {
        // state-change function to add new student
        fn add_student(
            ref self: ContractState,
            fname: felt252,
            lname: felt252,
            phone_number: felt252,
            age: u8,
            is_active: bool,
        ) -> bool {
            let id: u64 = self.total_no_of_students.read() + 1;
            assert(age > 0, 'age cannot be zero');
            let student = Student { id, fname, lname, phone_number, age, is_active };

            // add new student to storage
            self.students_map.entry(id).write(student);

            // increase student's count
            self.total_no_of_students.write(self.total_no_of_students.read() + 1);

            true
        }

        // read-only function to get student
        fn get_student(self: @ContractState, index: u64) -> (felt252, felt252, felt252, u8, bool) {
            let student = self.students_map.entry(index).read();
            assert(student.age > 0, Errors::STUDENT_NOT_REGISTERED);
            (student.fname, student.lname, student.phone_number, student.age, student.is_active)
        }


        /// Returns all students regardless of whether student is active or not
        /// Returns empty Span<Student> if there are no students, throwing error might be bad for UX
        /// on frontend
        fn get_all_students(self: @ContractState) -> Span<Student> {
            // empty array to store students
            let mut all_students: Array<Student> = array![];
            // total number of students
            let students_count = self.total_no_of_students.read();
            // counter
            let mut i = 1;

            while i < students_count + 1 {
                let current_student_data = self.students_map.entry(i).read();
                all_students.append(current_student_data);

                i += 1;
            };

            all_students.span()
        }

        fn update_student(
            ref self: ContractState,
            index: u64,
            fname: felt252,
            lname: felt252,
            phone_number: felt252,
            age: u8,
        ) -> bool {
            let old_student: Student = self.students_map.entry(index).read();
            // validation to check if student exist
            assert(old_student.age > 0, Errors::STUDENT_NOT_REGISTERED);
            let new_student = Student {
                id: index, fname, lname, phone_number, age, is_active: old_student.is_active,
            };
            assert(new_student.age > 0, 'age cannot be zero');
            // update student info
            self.students_map.entry(index).write(new_student);

            true
        }

        // Deleting a student is essentially deactivating the student
        // This function sets the is_active to false
        fn delete_student(ref self: ContractState, _index: u64) -> bool {
            let old_student: Student = self.students_map.entry(_index).read();
            // validation to check if student exist
            assert(old_student.age > 0, Errors::STUDENT_NOT_REGISTERED);
            let new_student = Student {
                id: old_student.id,
                fname: old_student.fname,
                lname: old_student.lname,
                phone_number: old_student.phone_number,
                age: old_student.age,
                is_active: false,
            };
            // update student info
            self.students_map.entry(_index).write(new_student);

            true
        }
    }


    #[generate_trait]
    impl Private of PrivateTrait {
        fn is_zero_address(self: @ContractState, account: ContractAddress) -> bool {
            if account.is_zero() {
                return true;
            }
            return false;
        }
    }
}
