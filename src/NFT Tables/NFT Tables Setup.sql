

CREATE TABLE owners (
    id BIGSERIAL PRIMARY KEY,
	created_at timestamp DEFAULT current_timestamp,
    owner_address varchar(45) UNIQUE
);

CREATE TABLE contracts (
    id BIGSERIAL PRIMARY KEY,
	created_at timestamp DEFAULT current_timestamp,
    contract_address varchar(45) UNIQUE,
	contract_name varchar(75),
	qty_minted numeric(78) NOT NULL DEFAULT 0,
	qty_burned numeric(78) NOT NULL DEFAULT 0,
	contract_type_id int
);
CREATE TABLE event_queue_nfts (
    block_number bigint,
    chain_id bigint,
    contract_address varchar(45),
    from_address varchar(45),
    to_address varchar(45),
    contract_type varchar(12),
    log_index int,
    operator varchar(45),
    supply numeric(78),
    created_at timestamp DEFAULT current_timestamp,
    token_id bigint,
    tx_hash varchar,
    PRIMARY KEY(tx_hash, log_index)
);

CREATE TABLE event_archive_nfts (
    block_number bigint,
    chain_id bigint,
    contract_address_id bigint REFERENCES contracts(id),
    from_address_id bigint REFERENCES owners(id),
    to_address_id bigint REFERENCES owners(id),
    log_index int,
    operator_address_id bigint REFERENCES owners(id),
    supply numeric(78),
    created_at timestamp,
    token_id bigint,
    tx_hash varchar,
    PRIMARY KEY(tx_hash, log_index)
);
CREATE TABLE contract_name_queue (
    contract_id bigint PRIMARY KEY,
    FOREIGN KEY (contract_id) REFERENCES contracts(id)
);
CREATE TABLE contract_types (
    id BIGSERIAL PRIMARY KEY,
	contract_type varchar(12) UNIQUE
);

INSERT into contract_types(contract_type) VALUES('ERC-20');
INSERT into contract_types(contract_type) VALUES('ERC-721');
INSERT into contract_types(contract_type) VALUES('ERC-1155');
INSERT into contract_types(contract_type) VALUES('');

CREATE TABLE nft_tokens (
    id bigint,
	created_at timestamp DEFAULT current_timestamp,
	updated_at timestamp,
    contract_address_id bigint REFERENCES contracts(id),
    qty_minted numeric(78) NOT NULL DEFAULT 0,
    qty_burned numeric(78) NOT NULL DEFAULT 0,
	meta_data json,
	meta_data_uri varchar,
	thumbnail varchar,
	image varchar,
	video varchar,
	block_number_uri bigint,
    PRIMARY KEY (id, contract_address_id)
);

CREATE TABLE nft_owners (
	created_at timestamp DEFAULT current_timestamp,
	updated_at timestamp,
    token_id bigint,
    contract_address_id bigint,
    owner_address_id bigint REFERENCES owners(id),
    qty_owned bigint,
    PRIMARY KEY (token_id, owner_address_id, contract_address_id),
    FOREIGN KEY (token_id, contract_address_id) REFERENCES nft_tokens(id, contract_address_id)
);

CREATE TABLE meta_data_queue (
    token_id bigint,
    contract_address_id bigint,
	created_at timestamp DEFAULT current_timestamp,
	uri varchar(100),
    PRIMARY KEY (token_id, contract_address_id),
    FOREIGN KEY (token_id, contract_address_id) REFERENCES nft_tokens(id, contract_address_id)
);