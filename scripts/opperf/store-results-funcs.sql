create or replace FUNCTION run_dxl_query(gpoptutils_namespace text, query_id text, query text) RETURNS void as $$
declare
	result text;
	restore_query text;
BEGIN
	-- insert entry for the given query if it doesn't exist already 
	insert into dxl_tests select query_id as id where not exists(select 1 from dxl_tests where id=query_id);
	
	BEGIN

	restore_query := 'select ' || gpoptutils_namespace || '.RestorePlanDXL(' || gpoptutils_namespace || '.DumpPlanDXL(' || quote_literal(query) || '))';

	execute restore_query into result;
	
	EXCEPTION
		WHEN OTHERS
		THEN
		result := substring(SQLERRM from 90 for 100);
	END;
	update dxl_tests set dxl = result where id=query_id;
	return;
END;
$$ LANGUAGE plpgsql;

create or replace FUNCTION run_gpdb_query(query_id text, query text) RETURNS void as $$
declare
	num_rows integer;
BEGIN
	-- insert entry for the given query if it doesn't exist already 
	insert into dxl_tests select query_id as id where not exists(select 1 from dxl_tests where id=query_id);
	
	execute query;
	
	GET DIAGNOSTICS num_rows = ROW_COUNT;
	
	update dxl_tests set gpdb = 'processed ' || num_rows || ' rows' where id=query_id;
	return;
END;
$$ LANGUAGE plpgsql;