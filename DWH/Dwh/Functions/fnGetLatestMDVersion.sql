CREATE FUNCTION [DwhDev].[fnGetLatestMDVersion]()
RETURNS INT
AS
BEGIN

	RETURN (SELECT MAX([version]) FROM [Dwh].[_Schema]);

END