
CREATE SCHEMA [DwhUat]
    AUTHORIZATION [dbo];


GO
GRANT CONTROL
    ON SCHEMA::[DwhUat] TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT INSERT
    ON SCHEMA::[DwhUat] TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT REFERENCES
    ON SCHEMA::[DwhUat] TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT SELECT
    ON SCHEMA::[DwhUat] TO [MeDriAnchorRole]
    AS [dbo];

