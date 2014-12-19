CREATE SCHEMA [Staging]
    AUTHORIZATION [dbo];


GO
GRANT CONTROL
    ON SCHEMA::[Staging] TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT INSERT
    ON SCHEMA::[Staging] TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT REFERENCES
    ON SCHEMA::[Staging] TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT SELECT
    ON SCHEMA::[Staging] TO [MeDriAnchorRole]
    AS [dbo];

