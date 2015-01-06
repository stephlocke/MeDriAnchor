
CREATE SCHEMA [Dwh]
    AUTHORIZATION [dbo];


GO
GRANT CONTROL
    ON SCHEMA::[Dwh] TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT INSERT
    ON SCHEMA::[Dwh] TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT REFERENCES
    ON SCHEMA::[Dwh] TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT SELECT
    ON SCHEMA::[Dwh] TO [MeDriAnchorRole]
    AS [dbo];

