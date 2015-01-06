
CREATE SCHEMA [MeDriAnchor]
    AUTHORIZATION [dbo];






GO
GRANT CONTROL
    ON SCHEMA::[MeDriAnchor] TO [MeDriAnchorRole];




GO
GRANT INSERT
    ON SCHEMA::[MeDriAnchor] TO [MeDriAnchorRole];




GO
GRANT REFERENCES
    ON SCHEMA::[MeDriAnchor] TO [MeDriAnchorRole];




GO
GRANT SELECT
    ON SCHEMA::[MeDriAnchor] TO [MeDriAnchorRole];



