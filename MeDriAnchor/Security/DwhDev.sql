
CREATE SCHEMA [DwhDev]
    AUTHORIZATION [dbo];





GO
GRANT CONTROL
    ON SCHEMA::[DwhDev] TO [MeDriAnchorRole];




GO
GRANT INSERT
    ON SCHEMA::[DwhDev] TO [MeDriAnchorRole];




GO
GRANT REFERENCES
    ON SCHEMA::[DwhDev] TO [MeDriAnchorRole];




GO
GRANT SELECT
    ON SCHEMA::[DwhDev] TO [MeDriAnchorRole];



