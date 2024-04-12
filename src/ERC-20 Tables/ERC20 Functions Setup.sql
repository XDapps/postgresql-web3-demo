CREATE OR REPLACE FUNCTION on_event_queue_erc20_add_row() RETURNS TRIGGER AS $$
DECLARE
       contract_id bigint;
       contract_type_id bigint;
	   address_to_id bigint;
	   address_from_id bigint;
BEGIN
    IF EXISTS (SELECT 1 FROM event_archive_erc20 WHERE tx_hash = NEW.tx_hash AND log_index = NEW.log_index) THEN
        DELETE FROM event_queue_erc20 WHERE tx_hash = NEW.tx_hash AND log_index = NEW.log_index;
    ELSE	
		SELECT DISTINCT INTO contract_id  confirmContractExists(NEW.contract_address, 'ERC-20', NEW.created_at);
		SELECT DISTINCT INTO address_from_id  confirmOwnerExists(NEW.from_address, NEW.created_at);
		SELECT DISTINCT INTO address_to_id  confirmOwnerExists(NEW.to_address, NEW.created_at);				
		SELECT DISTINCT id INTO contract_type_id FROM contract_types WHERE contract_type = 'ERC-20';

        IF NEW.from_address = '0x0000000000000000000000000000000000000000' THEN
			IF NOT EXISTS (SELECT 1 FROM erc20_owners WHERE contract_address_id = contract_id AND owner_address_id = address_to_id) THEN
				INSERT INTO erc20_owners (contract_address_id, owner_address_id, qty_owned, created_at) VALUES (contract_id, address_to_id, NEW.supply, NEW.created_at);
			ELSE
				UPDATE erc20_owners SET qty_owned = qty_owned + NEW.supply WHERE contract_address_id = contract_id AND owner_address_id = address_to_id;
            END IF;	
			
			UPDATE contracts SET qty_minted = qty_minted + NEW.supply WHERE id = contract_id;
		END IF;
		
        IF NEW.to_address= '0x0000000000000000000000000000000000000000' THEN
			UPDATE erc20_owners SET qty_owned = qty_owned - NEW.supply WHERE contract_address_id = contract_id AND owner_address_id = address_from_id;
			UPDATE contracts SET qty_burned = qty_burned + NEW.supply WHERE id = contract_id;
		END IF;
		
		IF NEW.from_address != '0x0000000000000000000000000000000000000000' AND NEW.to_address!= '0x0000000000000000000000000000000000000000' THEN
			IF NOT EXISTS (SELECT 1 FROM erc20_owners WHERE contract_address_id = contract_id AND owner_address_id = address_to_id) THEN
				INSERT INTO erc20_owners (contract_address_id, owner_address_id, qty_owned, created_at) VALUES (contract_id, address_to_id, NEW.supply, NEW.created_at);
			ELSE
				UPDATE erc20_owners SET qty_owned = qty_owned + NEW.supply WHERE contract_address_id = contract_id AND owner_address_id = address_to_id;
			END IF;
			UPDATE erc20_owners SET qty_owned = qty_owned - NEW.supply WHERE contract_address_id = contract_id AND owner_address_id = address_from_id;
		END IF;
		
		INSERT INTO event_archive_erc20(
			block_number, chain_id, log_index, supply, created_at, tx_hash)
		SELECT
			block_number, chain_id, log_index, supply, created_at, tx_hash
		FROM
			event_queue_erc20 WHERE tx_hash = NEW.tx_hash AND log_index = NEW.log_index;			
			
		UPDATE event_archive_erc20
		SET 
		contract_address_id = contract_id,
		from_address_id = address_from_id,
		to_address_id = address_to_id
		WHERE tx_hash = NEW.tx_hash AND log_index = NEW.log_index;	
			
		DELETE FROM event_queue_erc20 WHERE tx_hash = NEW.tx_hash AND log_index = NEW.log_index;
	END IF;

    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trigger_event_queue_erc20_add_row AFTER
INSERT ON event_queue_erc20
FOR EACH ROW EXECUTE FUNCTION on_event_queue_erc20_add_row();


CREATE OR REPLACE FUNCTION on_erc20_owners_update()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_erc20_owners_update
BEFORE UPDATE ON erc20_owners
FOR EACH ROW
EXECUTE PROCEDURE on_erc20_owners_update();

