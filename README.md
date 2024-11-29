<h1>Student Registry Contract</h1>
This is the backend of a simple student registry contract with capabilities to add, edit, fetch and delete* student records.

```cairo
// Adds a new student record to the contract
fn add_student(ref self: T, fname: felt252, lname: felt252, phone_number: felt252, age: u8, is_active: bool) -> bool;

// Fetches a student record by index
fn get_student(self: @T, index: u64) -> (felt252, felt252, felt252, u8, bool);

// Returns a span<Student> of all students, regardless of whether student is active or not
fn get_all_students(self: @T) -> Span<Student>;

// Update a student record( by index) with the arguments provided
fn update_student(ref self: T, index: u64, fname: felt252, lname: felt252, phone_number: felt252, age: u8) -> bool;

// Does not really delete student record. Essentially "deactivates" student. Only sets is_active to false for given student.
fn delete_student(ref self: T, _index: u64) -> bool;
