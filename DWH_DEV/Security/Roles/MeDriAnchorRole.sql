
CREATE ROLE [MeDriAnchorRole]
    AUTHORIZATION [dbo];


GO
EXEC sp_addrolemember 'MeDriAnchorRole', 'MeDriAnchorUser';
GO
EXEC sp_addrolemember 'db_owner', 'MeDriAnchorRole';

