CREATE FUNCTION [DwhUat].[fnGetLatestMDVersion]()
RETURNS INT
AS
BEGIN

	RETURN (SELECT MAX([version]) FROM [DwhUat].[_Schema]);

END