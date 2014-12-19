
CREATE SCHEMA [DwhDev]
    AUTHORIZATION [dbo];



GO
GRANT CONTROL
    ON SCHEMA::[DwhDev] TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT INSERT
    ON SCHEMA::[DwhDev] TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT REFERENCES
    ON SCHEMA::[DwhDev] TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT SELECT
    ON SCHEMA::[DwhDev] TO [MeDriAnchorRole]
    AS [dbo];

