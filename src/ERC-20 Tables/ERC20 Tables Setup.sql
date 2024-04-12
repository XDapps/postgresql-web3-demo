CREATE TABLE event_queue_erc20 (
    block_number bigint,
    chain_id int,
	contract_address varchar(45),
    contract_type varchar(12),
    from_address varchar(45),
    to_address varchar(45),
    log_index int,
    supply numeric(78),
	created_at timestamp DEFAULT current_timestamp,
	tx_hash varchar,
	PRIMARY KEY(tx_hash, log_index)
	
);

CREATE TABLE event_archive_erc20 (
    block_number bigint,
    chain_id int,
	contract_address_id bigint,
    from_address_id bigint,
    to_address_id bigint,
    log_index int,
    supply numeric(78),
	created_at timestamp DEFAULT current_timestamp,
	tx_hash varchar,
	PRIMARY KEY(tx_hash, log_index)
);

CREATE TABLE erc20_owners (
	created_at timestamp DEFAULT current_timestamp,
	updated_at timestamp,
    contract_address_id bigint REFERENCES contracts(id),
    owner_address_id bigint REFERENCES owners(id),
    qty_owned numeric(78),
    PRIMARY KEY (owner_address_id, contract_address_id)
);