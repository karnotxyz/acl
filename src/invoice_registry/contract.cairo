#[starknet::contract]
pub mod InvoiceRegistry {
    use crate::invoice_registry::interface::{InvoiceId, IInvoiceRegistry};
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};

    #[derive(PartialEq, starknet::Store, Drop, Clone, Copy)]
    pub enum Status {
        #[default]
        Unknown,
        Registered,
        Lent,
    }

    #[storage]
    struct Storage {
        pub invoice_status: Map<InvoiceId, Status>,
    }

    #[abi(embed_v0)]
    pub impl InvoiceRegistryImpl of IInvoiceRegistry<ContractState> {
        fn add_invoice(ref self: ContractState, invoice_id: InvoiceId) {
            let status = self.invoice_status.read(invoice_id);
            assert(status == Status::Unknown, 'Should not be registered');

            self.invoice_status.write(invoice_id, Status::Registered);
        }


        fn lend_invoice(ref self: ContractState, invoice_id: InvoiceId) {
            let status = self.invoice_status.read(invoice_id);
            assert(status != Status::Unknown, 'Should be registered');
            assert(status != Status::Lent, 'Already lent');

            self.invoice_status.write(invoice_id, Status::Lent);
        }
    }
}
