#[derive(Drop, Serde, PartialEq, starknet::Store)]
pub struct Student {
    pub id: u64,
    pub fname: felt252,
    pub lname: felt252,
    pub phone_number: felt252,
    pub age: u8,
    pub is_active: bool,
}
