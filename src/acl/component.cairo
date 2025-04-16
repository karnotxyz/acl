#[starknet::component]
pub mod AclComponent {
    use acl::acl::interface::IAcl;
    use starknet::ContractAddress;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use core::poseidon;

    #[storage]
    pub struct Storage {
        approvals: Map<(felt252, felt252, ContractAddress), bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {}

    #[embeddable_as(ACLImpl)]
    pub impl ACL<
        TContractState, +HasComponent<TContractState>,
    > of IAcl<ComponentState<TContractState>> {
        fn give_approval(
            ref self: ComponentState<TContractState>,
            function_selector: felt252,
            to: ContractAddress,
            args: Span<felt252>,
        ) {
            let hash = poseidon::poseidon_hash_span(args);
            self.approvals.write((function_selector, hash, to), true);
        }


        fn is_approved(
            self: @ComponentState<TContractState>,
            caller: ContractAddress,
            args: Span<felt252>,
        ) -> bool {
            let hash = poseidon::poseidon_hash_span(args);
            let execution_info = starknet::get_execution_info().unbox();
            let approved_till = self.approvals.read((execution_info.entry_point_selector, hash, caller));
            approved_till
        }
    }
}
