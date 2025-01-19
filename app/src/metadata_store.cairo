#[starknet::interface] 
trait IMetadataStorage<TContractState> { 
    fn register_metadata(
            ref self: TContractState,
            file_name: felt252,
            file_size: felt252,
            chunk_count: felt252,
            chunk_ids: Array<felt252>,
            root_hash: felt252,
        );
    fn get_metadata(
            self: @TContractState,
            root_hash: felt252,
        ) -> (
            felt252,       // file_name
            felt252,       // file_size
            felt252,       // chunk_count
            Array<felt252> // chunk_ids
        );
    fn verify_merkle_proof(
            self: @TContractState,
            root_hash: felt252,
            leaf: felt252,
            proof: Array<felt252>,
            index: felt252,
        ) -> bool;
} 

#[starknet::contract]
mod metadata_storage {
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map,
    };
    use core::pedersen::{pedersen, PedersenTrait};
    use core::hash::{HashStateTrait};
    use super::*;

    /// ----------------------------
    /// Storage
    /// ----------------------------
    #[storage]
    struct Storage {
        /// file_name_store: (root_hash) -> file_name
        file_name_store: Map<felt252, felt252>,
        /// file_size_store: (root_hash) -> file_size
        file_size_store: Map<felt252, felt252>,
        /// chunk_count_store: (root_hash) -> chunk_count
        chunk_count_store: Map<felt252, felt252>,
        /// chunk_id_store: (root_hash, index) -> chunk_id
        ///
        /// We store the index and root_hash both as `felt252`.
        chunk_id_store: Map<(felt252, felt252), felt252>,
    }

    #[abi(embed_v0)] 
    impl MetadataContract of super::IMetadataStorage<ContractState> {
        /// ---------------------------------------
        /// External Function: register_metadata
        /// ---------------------------------------
        /// Writes metadata into contract storage.
        ///
        /// Arguments:
        /// - file_name: felt252
        /// - file_size: felt252
        /// - chunk_count: felt252
        /// - chunk_ids: array of felt252
        /// - root_hash: unique key
        fn register_metadata(
            ref self: ContractState,
            file_name: felt252,
            file_size: felt252,
            chunk_count: felt252,
            chunk_ids: Array<felt252>,
            root_hash: felt252,
        ) {
            // Write file_name
            self.file_name_store.entry(root_hash).write( file_name);

            // Write file_size
            self.file_size_store.entry(root_hash).write(file_size);

            // Write chunk_count
            self.chunk_count_store.entry(root_hash).write(root_hash);

            // Write each chunk_id to storage
            // We interpret chunk_count as the length of `chunk_ids`.
            let chunk_ids_len: u32 = (chunk_ids.len()).into();

            // Convert chunk_count to u32 for iteration
            let chunk_count_u32: u32 = chunk_count.try_into().unwrap();

            if chunk_count_u32 != chunk_ids_len {
                // ensure the provided array length
                // matches the provided chunk_count.
                panic!("Mismatch between chunk_count and chunk_ids length");
            };

            // Loop over the chunk_ids
            let mut i = 0_u32;
            while i < chunk_ids_len {
                let chunk_id = match chunk_ids.get(i) {
                    Option::Some(x) => {*x.unbox()},
                    Option::None => panic!("Index out of range"),
                };
                self.chunk_id_store.entry((root_hash, i.into())).write(chunk_id);
                i += 1;
            }
        }

        // / ---------------------------------------
        // / View Function: get_metadata
        // / ---------------------------------------
        // / Reads back stored data. Returns:
        // / - file_name
        // / - file_size
        // / - chunk_count
        // / - chunk_ids (as an Array<felt252>)
        fn get_metadata(
            self: @ContractState,
            root_hash: felt252) -> (
            felt252,       // file_name
            felt252,       // file_size
            felt252,       // chunk_count
            Array<felt252> // chunk_ids
        ) {
            let file_name = self.file_name_store.entry(root_hash).read();
            let file_size = self.file_size_store.entry(root_hash).read();
            let chunk_count = self.chunk_count_store.entry(root_hash).read();

            let chunk_count_u64: u64 = chunk_count.try_into().unwrap();

            // Read all chunk_ids from storage
            let mut chunk_ids = ArrayTrait::new();
            let mut i: u64 = 0_u64;
            while i < chunk_count_u64 {
                let chunk_id = self.chunk_id_store.entry((root_hash, i.into())).read();
                chunk_ids.append(chunk_id);
                i += 1;
            };

            (
                file_name,
                file_size,
                chunk_count,
                chunk_ids,
            )
        }

        /// -----------------------------------
        /// verify_merkle_proof (view)
        /// -----------------------------------
        /// verifying a simple Merkle proof using Pedersen hashing.
        ///
        /// This is a **placeholder** example showing typical Pedersen-based
        /// Merkle path computation:
        ///
        ///   - `root_hash`: the claimed root of the tree
        ///   - `leaf`: the piece of data being verified
        ///   - `proof`: an array of sibling hashes
        ///   - `index`: a numeric representation of the path (0 = left, 1 = right)
        ///
        fn verify_merkle_proof(
            self: @ContractState,
            root_hash: felt252,
            leaf: felt252,
            proof: Array<felt252>,
            index: felt252,
        ) -> bool {
            let mut idx_u32: u32 = index.try_into().unwrap();

            let proof_len = proof.len();
            let mut current_hash = leaf;
            let mut i = 0_u32;
            while i < proof_len {
                let sibling = match proof.get(i) {
                    Option::Some(x) => {*x.unbox()},
                    Option::None => panic!("Index out of range"),
                };
                let side_bit = idx_u32 & 1; // Extract the least significant bit to determine the side
                idx_u32 = idx_u32 / 2; // Perform a right shift by 1

                if side_bit == 0 {
                    current_hash = pedersen(current_hash, sibling);
                } else {
                    current_hash = pedersen(sibling, current_hash);
                }
                i += 1;

            };

            // Return true if final hash matches the root
            current_hash == root_hash
        }
    }
}