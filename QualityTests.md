====== Data quality tests ======

MeDriAnchor can run data quality tests on data being inserted in the anchor model. Testing data as it's inserted into the database to ensure it's within reasonable limits can help flag up any issues before they occur.

===== Adding new tests =====

Tests are created in "MeDriAnchor/PostDeploy/06DWHTests.sql". These are then automatically inserted into the database, storing the test values in DBTableColumn, and the test type in DBTableColumnTests.

===== Test types =====

The full list of tests is stored in DBTableColumnTest:

  * BETWEEN (NUMERIC): Value between two numbers
  * BETWEEN (YEARS FROM VALUE): Value between two years based on column value
  * IS NOT BLANK: Value is not blank
  * IS NOT NULL: Value is not null
  * IS NUMERIC: Value is numeric
  * <> (STRING): Value does not equal a given string value
  * ISVALID (LOOKUP STRING): Value is a valid lookup in another column
  * > (LENGTH STRING): Value is a string greater than n in length

Test types are created in sspCreateDWHTests.sql.

===== Test format =====

<code>
INSERT INTO @Tests
   SELECT 'Schema',
          'View name',
          'Column name',
          'Test Type',
          'Test value 1',
          'Test value 2',
          'Lookup schema',
          'Lookup table',
          'Lookup column';
</code>

  * Schema - the schema the test value is from (usually MeDriAnchor)
  * View name - the view containing the column to test. This will be the view referenced in 03PopulateMeDriAnchorDPRGateway.sql when adding the attribute
  * Column name - the column in the view to add the test to
  * Test type - the type of test to apply to the value (see above for full list)
  * Test value 1 - the first value to pass to the test
  * Test value 2 - the second value to pass to the test
  * Lookup schema - the schema the lookup table is contained with in
  * Lookup table - The lookup table name
  * Lookup column - The column in the lookup table to check against

===== Add test =====

Add the code from the previous section into "06DWHTests.sql" (see introduction to "Adding new tests" section for path to file).

===== Examples =====

==== LTV between 0 and 85 ====

**Conditions**: LTV must be between 0 and 85.

<code>
INSERT INTO @Tests
   SELECT 'MeDriAnchor',
          'vAccountServicing', -- LTV comes from this view in the gateway
          'LoanToValue', -- Check the LoanToValue column
          'BETWEEN (NUMERIC)', -- We want to use the between test
          CONVERT (FLOAT, 0), -- BETWEEN takes two values, the first is the lower bound
          CONVERT (FLOAT, 85), -- The second value is the upper bound
          NULL, -- No lookup
          NULL,
          NULL;
</code>

==== Postcode must appear in lookup table ====

**Conditions**: The postcode must appear in the lookup table of postcodes

<code>
INSERT INTO @Tests
   SELECT 'MeDriAnchor',
          'vAddressOrigination', -- Postcodes are found in the AddressOrigination view
          'PostCode_trimmed', -- Use the PostCode_trimmed column
          'ISVALID (LOOKUP STRING)', -- Use the lookup test
          NULL, -- No value 1, since we're not checking between two values
          NULL, -- No value 2, since we're not checking between two values
          'MeDriAnchor', -- Postcode lookup table is in the MeDriAnchor schema
          'LookupPostcode', -- LookupPostcode table contains the lookup column
          'pcd_trimmed'; -- Column to lookup values in
</code>
