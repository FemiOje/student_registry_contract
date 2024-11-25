use starknet::{get_caller_address, ContractAddress};

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

use student_registry_contract::student_registry::IStudentRegistryDispatcher;
use student_registry_contract::student_registry::IStudentRegistryDispatcherTrait;
use student_registry_contract::student_struct::Student;

pub mod Accounts {
    use starknet::ContractAddress;
    use core::traits::TryInto;

    pub fn admin() -> ContractAddress {
        'admin'.try_into().unwrap()
    }

    pub fn account1() -> ContractAddress {
        'account1'.try_into().unwrap()
    }
}

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let constructor_args = array![Accounts::admin().into()];
    let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
    contract_address
}

#[test]
fn test_add_student() {
    let contract_address = deploy_contract("StudentRegistry");
    let student_registry_dispatcher = IStudentRegistryDispatcher { contract_address };

    student_registry_dispatcher.add_student('FirstName', 'LastName', 8012223333, 16, true);

    let actual = student_registry_dispatcher.get_student(1);
    let expected = ('FirstName', 'LastName', 8012223333, 16, true);

    assert(actual == expected, 'Student not added successfully');
}

#[test]
#[should_panic(expected: ('age cannot be 0',))]
fn test_add_zero_student() {
    let contract_address = deploy_contract("StudentRegistry");
    let student_registry_dispatcher = IStudentRegistryDispatcher { contract_address };

    student_registry_dispatcher.add_student('FirstName', 'LastName', 8012223333, 0, true);
}

#[test]
fn test_get_student() {
    let contract_address = deploy_contract("StudentRegistry");
    let student_registry_dispatcher = IStudentRegistryDispatcher { contract_address };

    student_registry_dispatcher.add_student('FirstName', 'LastName', 8012223333, 16, true);
    student_registry_dispatcher.add_student('FirstName2', 'LastName2', 8012223334, 17, true);

    let expected1 = ('FirstName', 'LastName', 8012223333, 16, true);
    let expected2 = ('FirstName2', 'LastName2', 8012223334, 17, true);

    assert(student_registry_dispatcher.get_student(1) == expected1, 'Wrong student fetched');

    assert(student_registry_dispatcher.get_student(2) == expected2, 'Wrong student fetched');
}

#[test]
#[should_panic(expected: ('STUDENT NOT REGISTERED!',))]
fn test_get_student_with_nonexistent_index() {
    let contract_address = deploy_contract("StudentRegistry");
    let student_registry_dispatcher = IStudentRegistryDispatcher { contract_address };

    student_registry_dispatcher.get_student(5);
}

#[test]
fn test_get_all_students() {
    let contract_address = deploy_contract("StudentRegistry");
    let student_registry_dispatcher = IStudentRegistryDispatcher { contract_address };

    student_registry_dispatcher.add_student('FirstName', 'LastName', 8012223333, 16, true);
    student_registry_dispatcher.add_student('FirstName2', 'LastName2', 8012223334, 17, false);

    let student1 = Student {
        id: 1,
        fname: 'FirstName',
        lname: 'LastName',
        phone_number: 8012223333,
        age: 16,
        is_active: true
    };

    let student2 = Student {
        id: 2,
        fname: 'FirstName2',
        lname: 'LastName2',
        phone_number: 8012223334,
        age: 17,
        is_active: false
    };

    let all_students = array![student1, student2].span();

    assert(
        student_registry_dispatcher.get_all_students() == all_students, 'error getting all students'
    );
}

#[test]
fn test_get_all_students_empty() {
    let contract_address = deploy_contract("StudentRegistry");
    let student_registry_dispatcher = IStudentRegistryDispatcher { contract_address };

    student_registry_dispatcher.get_all_students();
}

#[test]
fn test_update_student() {
    let contract_address = deploy_contract("StudentRegistry");
    let student_registry_dispatcher = IStudentRegistryDispatcher { contract_address };

    student_registry_dispatcher.add_student('FirstName', 'LastName', 8012223333, 16, true);
    student_registry_dispatcher.add_student('FirstName2', 'LastName2', 8012223334, 17, false);

    student_registry_dispatcher
        .update_student(1, 'FirstNameEdited', 'LastNameEdited', 8012223334, 17);
    student_registry_dispatcher
        .update_student(2, 'FirstName2Edited', 'LastName2Edited', 8012223335, 18);

    let actual1 = student_registry_dispatcher.get_student(1);
    let actual2 = student_registry_dispatcher.get_student(2);

    let expected1 = ('FirstNameEdited', 'LastNameEdited', 8012223334, 17, true);
    let expected2 = ('FirstName2Edited', 'LastName2Edited', 8012223335, 18, false);

    assert(actual1 == expected1, 'Student not updated.');
    assert(actual2 == expected2, 'Student not updated.');
}

#[test]
#[should_panic(expected: ('STUDENT NOT REGISTERED!',))]
fn test_update_nonexistent_student() {
    let contract_address = deploy_contract("StudentRegistry");
    let student_registry_dispatcher = IStudentRegistryDispatcher { contract_address };

    student_registry_dispatcher
        .update_student(1, 'FirstNameEdited', 'LastNameEdited', 8012223334, 17);
}

#[test]
#[should_panic(expected: ('age cannot be zero',))]
fn test_update_student_age_to_zero() {
    let contract_address = deploy_contract("StudentRegistry");
    let student_registry_dispatcher = IStudentRegistryDispatcher { contract_address };

    student_registry_dispatcher.add_student('FirstName', 'LastName', 8012223333, 16, true);
    student_registry_dispatcher
        .update_student(1, 'FirstNameEdited', 'LastNameEdited', 8012223334, 0);
}

#[test]
fn test_delete_student() {
    let contract_address = deploy_contract("StudentRegistry");
    let student_registry_dispatcher = IStudentRegistryDispatcher { contract_address };

    student_registry_dispatcher.add_student('FirstName', 'LastName', 8012223333, 16, true);
    student_registry_dispatcher.delete_student(1);
}

#[test]
fn test_delete_student_and_check() {
    let contract_address = deploy_contract("StudentRegistry");
    let student_registry_dispatcher = IStudentRegistryDispatcher { contract_address };

    student_registry_dispatcher.add_student('FirstName', 'LastName', 8012223333, 16, true);
    student_registry_dispatcher.add_student('FirstName2', 'LastName2', 8012223334, 17, true);

    student_registry_dispatcher.delete_student(1);

    let actual: Span<Student> = student_registry_dispatcher.get_all_students();
    let expected = array![
        Student {
            id: 1,
            fname: 'FirstName',
            lname: 'LastName',
            phone_number: 8012223333,
            age: 16,
            is_active: false
        },
        Student {
            id: 2,
            fname: 'FirstName2',
            lname: 'LastName2',
            phone_number: 8012223334,
            age: 17,
            is_active: true
        }
    ]
        .span();

    assert(actual == expected, 'Student not deleted.');
}


#[test]
#[should_panic(expected: ('STUDENT NOT REGISTERED!',))]
fn test_delete_nonexistent_student() {
    let contract_address = deploy_contract("StudentRegistry");
    let student_registry_dispatcher = IStudentRegistryDispatcher { contract_address };

    student_registry_dispatcher.delete_student(1);
}
