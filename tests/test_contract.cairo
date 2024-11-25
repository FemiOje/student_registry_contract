use starknet::{get_caller_address, ContractAddress};

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait};

use student_registry_contract::student_registry::IStudentRegistryDispatcher;
use student_registry_contract::student_registry::IStudentRegistryDispatcherTrait;

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

    let expected = ('FirstName', 'LastName', 8012223333, 16, true);

    assert(
        student_registry_dispatcher.get_student(1) == expected, 'Student not added successfully'
    );
}

#[test]
#[should_panic(expected: ('age cannot be 0',))]
fn test_add_zero_student() {
    let contract_address = deploy_contract("StudentRegistry");
    let student_registry_dispatcher = IStudentRegistryDispatcher { contract_address };

    student_registry_dispatcher.add_student('FirstName', 'LastName', 8012223333, 0, true);
}
