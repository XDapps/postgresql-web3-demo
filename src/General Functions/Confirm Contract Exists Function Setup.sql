CREATE OR REPLACE FUNCTION confirmContractExists(contract_to_check varchar(45), contract_type_param varchar(12), created_at_param  timestamp)
RETURNS integer AS $contract_id$
DECLARE
       contract_type_id bigint;
       contract_id bigint;
BEGIN
		IF NOT EXISTS (SELECT 1 FROM contracts WHERE contract_address = contract_to_check) THEN
			SELECT DISTINCT id INTO contract_type_id FROM contract_types WHERE contract_type = contract_type_param;
			INSERT INTO contracts (contract_address, contract_type_id, created_at) VALUES (contract_to_check, contract_type_id, created_at_param);
			SELECT DISTINCT id INTO contract_id FROM contracts WHERE contract_address = contract_to_check;
			INSERT INTO contract_name_queue (contract_id) VALUES (contract_id);			
		ELSE	
			SELECT DISTINCT id INTO contract_id FROM contracts WHERE contract_address = contract_to_check;
		END IF;	
		RETURN contract_id;
END;
$contract_id$ LANGUAGE 'plpgsql';