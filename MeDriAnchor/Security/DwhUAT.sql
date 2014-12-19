
CREATE SCHEMA [DwhUAT]
    AUTHORIZATION [dbo];


GO
GRANT CONTROL
    ON SCHEMA::[DwhUAT] TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT INSERT
    ON SCHEMA::[DwhUAT] TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT REFERENCES
    ON SCHEMA::[DwhUAT] TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT SELECT
    ON SCHEMA::[DwhUAT] TO [MeDriAnchorRole]
    AS [dbo];

