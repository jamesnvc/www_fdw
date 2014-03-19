create extension www_fdw;

create server www_fdw_test FOREIGN DATA WRAPPER www_fdw
OPTIONS (
  uri 'http://localhost:3002/buckets/thing/entities',
  response_deserialize_callback 'test_response_deserialize_cb'
);

create user mapping for CURRENT_USER server www_fdw_test ;

create foreign table www_fdw_test (id bigint, name text, email text) server www_fdw_test ;

create function test_response_deserialize_cb(options WWWFdwOptions, response text)
RETURNS SETOF www_fdw_test AS $$
DECLARE
  entry json;
  r www_fdw_test%ROWTYPE;
BEGIN
  -- json_populate_recordset doesn't work here because the tags field is an array and
  -- as of postgres 9.3 json_populate_recordset fails with nested objects
  --RETURN QUERY select id, name, email from
    --json_populate_recordset(null::www_fdw_test, response::json, false);
  FOR entry IN SELECT value as value FROM json_array_elements(response::json) LOOP
    r := ROW(entry->'id', entry->>'name', entry->>'email');
    RETURN NEXT r;
  END LOOP;
END;
$$ LANGUAGE PLPGSQL;

select * from www_fdw_test;
