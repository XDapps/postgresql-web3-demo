CREATE OR REPLACE FUNCTION on_event_queue_nfts_add_row() RETURNS TRIGGER AS $$
DECLARE
       contract_id bigint;
       contract_type_id bigint;
	   address_to_id bigint;
	   address_from_id bigint;
	   operator_address_id_var bigint;
BEGIN
    IF EXISTS (SELECT 1 FROM event_archive_nfts WHERE tx_hash = NEW.tx_hash AND log_index = NEW.log_index) THEN
        DELETE FROM event_queue_nfts WHERE tx_hash = NEW.tx_hash AND log_index = NEW.log_index;
    ELSE
		SELECT DISTINCT INTO contract_id  confirmContractExists(NEW.contract_address, NEW.contract_type, NEW.created_at);
		SELECT DISTINCT INTO address_to_id confirmOwnerExists(NEW.to_address, NEW.created_at);
		SELECT DISTINCT INTO address_from_id confirmOwnerExists(NEW.from_address, NEW.created_at);
		SELECT DISTINCT INTO operator_address_id_var confirmOwnerExists(NEW.operator, NEW.created_at);		

        IF NEW.from_address = '0x0000000000000000000000000000000000000000' THEN
			IF NOT EXISTS (SELECT 1 FROM nft_tokens WHERE id = NEW.token_id AND contract_address_id = contract_id) THEN
				INSERT INTO nft_tokens (id, contract_address_id, qty_minted, created_at) VALUES (NEW.token_id, contract_id, NEW.supply, NEW.created_at);
				INSERT INTO meta_data_queue (token_id, contract_address_id, created_at) VALUES (NEW.token_id, contract_id, NEW.created_at);
			ELSE
				UPDATE nft_tokens SET qty_minted = qty_minted + NEW.supply WHERE id = NEW.token_id AND contract_address_id = contract_id;
			END IF;
            
			IF NOT EXISTS (SELECT 1 FROM nft_owners WHERE token_id = NEW.token_id AND contract_address_id = contract_id AND owner_address_id = address_to_id) THEN
				INSERT INTO nft_owners (token_id, contract_address_id, owner_address_id, qty_owned, created_at) VALUES (NEW.token_id, contract_id, address_to_id, NEW.supply, NEW.created_at);
			ELSE
				UPDATE nft_owners SET qty_owned = qty_owned + NEW.supply WHERE token_id = NEW.token_id AND contract_address_id = contract_id AND owner_address_id = address_to_id;
            END IF;	
			
			UPDATE contracts SET qty_minted = qty_minted + NEW.supply WHERE id = contract_id;
		END IF;
		
        IF NEW.to_address= '0x0000000000000000000000000000000000000000' THEN
			UPDATE nft_tokens SET qty_burned = qty_burned + NEW.supply WHERE id = NEW.token_id AND contract_address_id = contract_id;
            UPDATE nft_owners SET qty_owned = qty_owned - NEW.supply WHERE token_id = NEW.token_id AND contract_address_id = contract_id AND owner_address_id = address_from_id;
			UPDATE contracts SET qty_burned = qty_burned + NEW.supply WHERE id = contract_id;
		END IF;
		
		IF NEW.from_address != '0x0000000000000000000000000000000000000000' AND NEW.to_address!= '0x0000000000000000000000000000000000000000' THEN
			IF NOT EXISTS (SELECT 1 FROM nft_owners WHERE token_id = NEW.token_id AND contract_address_id = contract_id AND owner_address_id = address_to_id) THEN
				INSERT INTO nft_owners (token_id, contract_address_id, owner_address_id, qty_owned, created_at) VALUES (NEW.token_id, contract_id, address_to_id, NEW.supply, NEW.created_at);
			ELSE
				UPDATE nft_owners SET qty_owned = qty_owned + NEW.supply WHERE token_id = NEW.token_id AND contract_address_id = contract_id AND owner_address_id = address_to_id;
			END IF;
			UPDATE nft_owners SET qty_owned = qty_owned - NEW.supply WHERE token_id = NEW.token_id AND contract_address_id = contract_id AND owner_address_id = address_from_id;
		END IF;
		
		INSERT INTO event_archive_nfts(
			block_number, chain_id, log_index, supply, created_at, token_id, tx_hash)
		SELECT
			block_number, chain_id, log_index, supply, created_at, token_id, tx_hash
		FROM
			event_queue_nfts WHERE tx_hash = NEW.tx_hash AND log_index = NEW.log_index;			
			
		UPDATE event_archive_nfts
		SET 
		contract_address_id = contract_id,
		from_address_id = address_from_id,
		to_address_id = address_to_id,
		operator_address_id = operator_address_id_var
		WHERE tx_hash = NEW.tx_hash AND log_index = NEW.log_index;			
			
		DELETE FROM event_queue_nfts WHERE tx_hash = NEW.tx_hash AND log_index = NEW.log_index;
	END IF;

    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trigger_event_queue_nfts_add_row AFTER
INSERT ON event_queue_nfts
FOR EACH ROW EXECUTE FUNCTION on_event_queue_nfts_add_row();


CREATE OR REPLACE FUNCTION on_nft_tokens_update()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_nft_tokens_update
BEFORE UPDATE ON nft_tokens
FOR EACH ROW
EXECUTE PROCEDURE on_nft_tokens_update();


CREATE OR REPLACE FUNCTION on_nft_owners_update()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_nft_owners_update
BEFORE UPDATE ON nft_owners
FOR EACH ROW
EXECUTE PROCEDURE on_nft_owners_update();

