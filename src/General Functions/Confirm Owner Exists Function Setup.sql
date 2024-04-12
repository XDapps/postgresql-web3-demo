CREATE OR REPLACE FUNCTION confirmOwnerExists(owner_to_check varchar(45), created_at_param  timestamp)
RETURNS integer AS $owner_id$
DECLARE
       owner_id bigint;
BEGIN
		IF NOT EXISTS (SELECT 1 FROM owners WHERE owner_address = owner_to_check) THEN
			INSERT INTO owners (owner_address, created_at) VALUES (owner_to_check, created_at_param);
			SELECT DISTINCT id INTO owner_id FROM owners WHERE owner_address = owner_to_check;	
		ELSE	
			SELECT DISTINCT id INTO owner_id FROM owners WHERE owner_address = owner_to_check;
		END IF;	
		RETURN owner_id;
END;
$owner_id$ LANGUAGE 'plpgsql';