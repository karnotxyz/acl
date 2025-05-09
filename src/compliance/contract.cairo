#[starknet::contract]
pub mod ComplianceContract {
    use starknet::storage::{StoragePointerWriteAccess, StorableStoragePointerReadAccess};
    use crate::compliance::interface::ICompliance;

    #[storage]
    struct Storage {
        fee: u8,
    }

    #[constructor]
    fn constructor(ref self: ContractState, fee: u8) {
        self.fee.write(fee);
    }

    #[abi(embed_v0)]
    pub impl ICompliancImpl of ICompliance<ContractState> {
        fn set_fee(ref self: ContractState, fee: u8) {
            self.fee.write(fee);
        }

        fn get_fee(self: @ContractState) -> u8 {
            self.fee.read()
        }
    }
}
