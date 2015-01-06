CREATE FUNCTION [DwhDev].[fnGetLatestMDVersion]()
RETURNS INT
AS
BEGIN

	RETURN (SELECT MAX([version]) FROM [DwhDev].[_Schema]);

END