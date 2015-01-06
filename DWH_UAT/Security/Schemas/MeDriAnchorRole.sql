CREATE ROLE [MeDriAnchorRole]
    AUTHORIZATION [dbo];


GO
EXEC sp_addrolemember 'MeDriAnchorRole', 'MeDriAnchorUser';

