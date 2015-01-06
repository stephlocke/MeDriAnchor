
CREATE SCHEMA [MeDriAnchor]
    AUTHORIZATION [dbo];


GO
GRANT CONTROL
    ON SCHEMA::[MeDriAnchor] TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT INSERT
    ON SCHEMA::[MeDriAnchor] TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT REFERENCES
    ON SCHEMA::[MeDriAnchor] TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT SELECT
    ON SCHEMA::[MeDriAnchor] TO [MeDriAnchorRole]
    AS [dbo];

