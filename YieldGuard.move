
module permissionLessHackathon::YieldGuard {
    use aptos_std::smart_table;
    use aptos_framework::signer;

    // Define the key and value types for the smart table
    struct DataKey has copy, drop, store {
        key: u64
    }

    struct DataValue has copy, drop, store {
        value: vector<u8>
    }

    struct DataStore has key {
        yg_table: smart_table::SmartTable<DataKey, DataValue>,
    }

    // New struct to return both keys and values
    struct KeyValueData has copy, drop, store {
        keys: vector<u64>,
        values: vector<vector<u8>>,
    }

    // Initialize the SmartTable and store it under the owner's address.
    fun yg_init(owner: &signer) {
        let yg_table = smart_table::new<DataKey, DataValue>();
        move_to(owner, DataStore { yg_table });
    }

    // Submit encrypted data by providing a unique ID and encrypted vector<u8>.
    fun submitEncryptedData(owner: &signer, anonymousFarmerId: u64, encryptedData: vector<u8>) acquires DataStore {
        let data_store = borrow_global_mut<DataStore>(signer::address_of(owner));

        let key = DataKey { key: anonymousFarmerId };
        let value = DataValue { value: encryptedData };

        smart_table::add(&mut data_store.yg_table, key, value);
    }

    // Function to retrieve all keys and values from the smart_table.
    fun get_all_entries(owner: &signer): KeyValueData acquires DataStore {
        let data_store = borrow_global<DataStore>(signer::address_of(owner));

        let all_keys: vector<u64> = vector::empty();
        let all_values: vector<vector<u8>> = vector::empty();

        let keys = smart_table::keys(&data_store.yg_table);

        // Loop through each key (DataKey), retrieve the corresponding value, and store them in vectors.
        let i = 0;
        while (i < vector::length(&keys)) {
            let data_key = vector::borrow(&keys, i);
            let data_value = smart_table::borrow(&data_store.yg_table, data_key);

            // Extract the `u64` key from the `DataKey` struct.
            vector::push_back(&mut all_keys, data_key.key);
            vector::push_back(&mut all_values, data_value.value);

            i = i + 1;
        }

        // Return both keys and values in a KeyValueData struct and add a semicolon
        KeyValueData { keys: all_keys, values: all_values };
    }

    #[test_only]
    use std::debug::print;

    #[test(owner = @0x123)]
    fun test_fun(owner: signer) acquires DataStore {
        yg_init(&owner);
        let data: vector<u8> = b"This is encrypted data";
        let id1: u64 = 86;
        let id2: u64 = 2024;
        let id3: u64 = 1999;
        submitEncryptedData(&owner, id1, data);
        submitEncryptedData(&owner, id2, data);
        submitEncryptedData(&owner, id3, data);

        // Print the keys and values using the new struct.
        let key_value_data = get_all_entries(&owner);
        print(&key_value_data.keys);
        print(&key_value_data.values);
    }
}
