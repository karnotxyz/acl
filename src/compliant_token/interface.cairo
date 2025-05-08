use starknet::ContractAddress;
use acl::onchain_id::interface::Topic;

#[derive(Drop, Clone, Serde, starknet::Store)]
pub struct Claim {
    pub topic: Topic,
    pub issuer: ContractAddress,
}

#[starknet::interface]
pub trait ICompliantToken<TState> {
    fn add_claim_check(ref self: TState, claim: Claim);
    fn add_compliance_check(ref self: TState, compliance_module: ContractAddress);
}

