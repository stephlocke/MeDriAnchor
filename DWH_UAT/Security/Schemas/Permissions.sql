GRANT CONNECT TO [MeDriAnchorUser]
    AS [dbo];


GO
GRANT CREATE PROCEDURE TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT CREATE TABLE TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT CREATE VIEW TO [MeDriAnchorRole]
    AS [dbo];


GO
GRANT REFERENCES
    ON SCHEMA::[dbo] TO [MeDriAnchorRole]
    AS [dbo];

