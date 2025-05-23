#[starknet::contract]
mod CompliantToken {
    use ERC20Component::InternalTrait;
    use starknet::storage::{
        Vec, MutableVecTrait, StoragePointerWriteAccess, StoragePointerReadAccess,
    };
    use starknet::{ContractAddress, get_caller_address};
    use crate::compliant_token::interface::{ICompliantToken, Claim};
    use crate::acl::component::{AclComponent};
    use crate::acl::interface::IAcl;
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::token::erc20::interface::IERC20Metadata;
    use openzeppelin::token::erc20::interface::IERC20;
    use core::integer::u256;
    use core::array::ArrayTrait;
    use core::traits::Into;
    use core::num::traits::Zero;
    use acl::onchain_id::interface::{IOnchainIdDispatcher, IOnchainIdDispatcherTrait};
    use crate::compliance::interface::{IComplianceDispatcher, IComplianceDispatcherTrait};
    use crate::identity_registry::interface::{
        IIdentityRegistryDispatcher, IIdentityRegistryDispatcherTrait,
    };

    component!(path: ERC20Component, storage: erc20, event: erc20);
    component!(path: AclComponent, storage: acl, event: acl);
    component!(path: OwnableComponent, storage: ownable, event: ownable);

    // ERC20
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
    impl ERC20Internal = ERC20Component::InternalImpl<ContractState>;

    // ACL
    impl AclImpl = AclComponent::AclImpl<ContractState>;
    impl AclInternal = AclComponent::IAclInternalImpl<ContractState>;

    // Ownable
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternal = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    pub struct Storage {
        pub required_claims: Vec<Claim>,
        pub compliance_modules: Vec<ContractAddress>,
        pub identity_registry: IIdentityRegistryDispatcher,
        #[substorage(v0)]
        pub erc20: ERC20Component::Storage,
        #[substorage(v0)]
        pub acl: AclComponent::Storage,
        #[substorage(v0)]
        pub ownable: OwnableComponent::Storage,
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        erc20: ERC20Component::Event,
        #[flat]
        acl: AclComponent::Event,
        #[flat]
        ownable: OwnableComponent::Event,
    }


    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        identity_registry: ContractAddress,
        initial_supply: felt252,
        name: ByteArray,
        symbol: ByteArray,
    ) {
        self.ownable.initializer(owner);
        self.erc20.initializer(name, symbol);
        self.erc20.mint(owner, initial_supply.into());

        let identity_registry_dispatcher = IIdentityRegistryDispatcher {
            contract_address: identity_registry,
        };
        self.identity_registry.write(identity_registry_dispatcher);
    }

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
    impl MyAclImpl of IAcl<ContractState> {
        fn give_approval(
            ref self: ContractState,
            function_selector: felt252,
            to: ContractAddress,
            args: Span<felt252>,
        ) {
            let caller = get_caller_address();
            if function_selector == selector!("balance_of") {
                assert(caller.into() == *args[0], 'Caller not the owner');
            } else if function_selector == selector!("total_supply")
                || function_selector == selector!("decimals")
                || function_selector == selector!("symbol")
                || function_selector == selector!("name") {
                assert(caller.into() == self.ownable.owner(), 'Caller not the owner');
            };

            self.acl.give_approval(function_selector, to, args);
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
            let receiver_onChainId_address = self.identity_registry.read().get_identity(recipient);
            assert(receiver_onChainId_address.is_non_zero(), 'Receiver is not registered');
            let receiver_onChainId_dispatcher = IOnchainIdDispatcher {
                contract_address: receiver_onChainId_address,
            };

            for i in 0..self.required_claims.len() {
                let claim = self.required_claims.at(i).read();
                let claim_exists = receiver_onChainId_dispatcher
                    .claim_exists(claim.topic, claim.issuer);
                assert(claim_exists, 'Receiver should have the claim');
            };

            let mut fee_in_basis = 0;
            for i in 0..self.compliance_modules.len() {
                let compliance_module = self.compliance_modules.at(i).read();
                let compliance_module_dispatcher = IComplianceDispatcher {
                    contract_address: compliance_module,
                };
                let fee = compliance_module_dispatcher.get_fee();
                fee_in_basis += fee.into();
            };

            let fee_amt = amount * fee_in_basis / 100_00;
            self.erc20.transfer(self.ownable.owner(), fee_amt);
            self.erc20.transfer(recipient, amount - fee_amt)
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
