
CREATE SCHEMA [DwhUAT]
    AUTHORIZATION [dbo];




GO
GRANT CONTROL
    ON SCHEMA::[DwhUAT] TO [MeDriAnchorRole];




GO
GRANT INSERT
    ON SCHEMA::[DwhUAT] TO [MeDriAnchorRole];




GO
GRANT REFERENCES
    ON SCHEMA::[DwhUAT] TO [MeDriAnchorRole];




GO
GRANT SELECT
    ON SCHEMA::[DwhUAT] TO [MeDriAnchorRole];



