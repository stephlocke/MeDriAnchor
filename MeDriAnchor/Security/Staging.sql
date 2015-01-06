CREATE SCHEMA [Staging]
    AUTHORIZATION [dbo];




GO
GRANT CONTROL
    ON SCHEMA::[Staging] TO [MeDriAnchorRole];




GO
GRANT INSERT
    ON SCHEMA::[Staging] TO [MeDriAnchorRole];




GO
GRANT REFERENCES
    ON SCHEMA::[Staging] TO [MeDriAnchorRole];




GO
GRANT SELECT
    ON SCHEMA::[Staging] TO [MeDriAnchorRole];



