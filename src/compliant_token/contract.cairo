#[starknet::contract]
mod CompliantToken {
    use starknet::storage::{Vec, MutableVecTrait, StoragePointerWriteAccess};
    use starknet::ContractAddress;
    use acl::compliant_token::interface::{ICompliantToken, Claim};
    use acl::acl::component::AclComponent;
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use openzeppelin::token::erc20::interface::IERC20Metadata;
    use openzeppelin::token::erc20::interface::IERC20;
    use core::integer::u256;
    use core::array::ArrayTrait;
    use core::traits::Into;

    component!(path: ERC20Component, storage: erc20, event: erc20);
    component!(path: AclComponent, storage: acl, event: acl);

    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
    impl ERC20Internal = ERC20Component::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl AclImpl = AclComponent::AclImpl<ContractState>;
    impl AclInternal = AclComponent::IAclInternalImpl<ContractState>;

    #[storage]
    pub struct Storage {
        pub required_claims: Vec<Claim>,
        pub compliance_modules: Vec<ContractAddress>,
        #[substorage(v0)]
        pub erc20: ERC20Component::Storage,
        #[substorage(v0)]
        pub acl: AclComponent::Storage,
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        erc20: ERC20Component::Event,
        #[flat]
        acl: AclComponent::Event,
    }


    #[constructor]
    fn constructor(ref self: ContractState) {}

    #[abi(embed_v0)]
    impl ICompliantTokenImpl of ICompliantToken<ContractState> {
        fn add_compliance_check(ref self: ContractState, compliance_module: ContractAddress) {
            self.compliance_modules.append().write(compliance_module);
        }

        fn add_claim_check(ref self: ContractState, claim: Claim) {
            self.required_claims.append().write(claim);
        }
    }

    #[abi(embed_v0)]
    impl MyERC20Impl of IERC20<ContractState> {
        fn total_supply(self: @ContractState) -> u256 {
            let mut args = ArrayTrait::new();
            self.acl.is_approved(args.span());
            self.erc20.total_supply()
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            let mut args = ArrayTrait::new();
            account.serialize(ref args);
            self.acl.is_approved(args.span());
            self.erc20.balance_of(account)
        }

        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress,
        ) -> u256 {
            let mut args = ArrayTrait::new();
            owner.serialize(ref args);
            spender.serialize(ref args);
            self.acl.is_approved(args.span());
            self.erc20.allowance(owner, spender)
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            self.erc20.transfer(recipient, amount)
        }

        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
        ) -> bool {
            self.erc20.transfer_from(sender, recipient, amount)
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            self.erc20.approve(spender, amount)
        }
    }


    #[abi(embed_v0)]
    impl MyERC20MetadataImpl of IERC20Metadata<ContractState> {
        fn name(self: @ContractState) -> ByteArray {
            let mut args = ArrayTrait::new();
            self.acl.is_approved(args.span());
            self.erc20.name()
        }

        fn symbol(self: @ContractState) -> ByteArray {
            let mut args = ArrayTrait::new();
            self.acl.is_approved(args.span());
            self.erc20.symbol()
        }

        fn decimals(self: @ContractState) -> u8 {
            let mut args = ArrayTrait::new();
            self.acl.is_approved(args.span());
            self.erc20.decimals()
        }
    }
}
