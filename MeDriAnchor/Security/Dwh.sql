
CREATE SCHEMA [Dwh]
    AUTHORIZATION [dbo];




GO
GRANT CONTROL
    ON SCHEMA::[Dwh] TO [MeDriAnchorRole];




GO
GRANT INSERT
    ON SCHEMA::[Dwh] TO [MeDriAnchorRole];




GO
GRANT REFERENCES
    ON SCHEMA::[Dwh] TO [MeDriAnchorRole];




GO
GRANT SELECT
    ON SCHEMA::[Dwh] TO [MeDriAnchorRole];



