use starknet::ContractAddress;

#[starknet::interface]
pub trait IIdentityRegistry<TContractState> {
    fn register_identity(
        ref self: TContractState, user_address: ContractAddress, identity: ContractAddress,
    );


    fn get_identity(self: @TContractState, user_address: ContractAddress) -> ContractAddress;

    fn get_new_identity(ref self: TContractState, user: ContractAddress) -> ContractAddress;
    fn register_my_identity(ref self: TContractState, identity: ContractAddress);
}
