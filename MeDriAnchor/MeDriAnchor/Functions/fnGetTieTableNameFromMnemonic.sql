
CREATE FUNCTION [MeDriAnchor].[fnGetTieTableNameFromMnemonic](@TieMnemonic SYSNAME)
RETURNS SYSNAME
AS
BEGIN

	DECLARE @TableName SYSNAME = '';

	SELECT @TableName += ties.[Ref] + '_' + ties.[RoleName] + '_'
	FROM
	(
	SELECT	'Anchor' As [Type],
			ttc.[AnchorMnemonicRef] AS [Ref],
			ttc.[RoleName],
			ttc.[TieJoinOrder]
	FROM [MeDriAnchor].[DBTableTie] tt
	INNER JOIN [MeDriAnchor].[DBTableTieColumns] ttc
		ON ttc.[TieID] = tt.[TieID]
	WHERE tt.[TieMnemonic] = @TieMnemonic
	UNION ALL
	SELECT	'Knot' AS [Type],
			tt.[KnotMnemonic] AS [Ref],
			tt.[KnotRoleName] AS [RoleName], 
			99999 AS [[TieJoinOrder]
	FROM [MeDriAnchor].[DBTableTie] tt
	WHERE tt.[TieMnemonic] = @TieMnemonic
		AND [KnotMnemonic] <> ''
	) ties
	ORDER BY ties.[Type], ties.[TieJoinOrder], ties.[Ref], ties.[RoleName];

	SET @TableName = (CASE WHEN @TableName = '' THEN '' ELSE LEFT(@TableName, LEN(@TableName) - 1) END)

	RETURN @TableName;

END
