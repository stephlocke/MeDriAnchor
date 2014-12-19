CREATE FUNCTION [MeDriAnchor].[fnHasMetadataChanged]()
RETURNS BIT
AS
BEGIN

	DECLARE @MetadataChanged BIT;
	DECLARE @Metadata_ID BIGINT = (SELECT MAX([Metadata_ID]) FROM [MeDriAnchor].[Metadata]);

	IF ((@Metadata_ID IS NULL) OR EXISTS	
			(
			SELECT [Metadata_ID] FROM [MeDriAnchor].[DBServerType_Shadow] WHERE ISNULL([Metadata_ID], 0) = @Metadata_ID UNION ALL
			SELECT [Metadata_ID] FROM [MeDriAnchor].[DBServer_Shadow] WHERE ISNULL([Metadata_ID], 0) = @Metadata_ID UNION ALL
			SELECT [Metadata_ID] FROM [MeDriAnchor].[DB_Shadow] WHERE ISNULL([Metadata_ID], 0) = @Metadata_ID UNION ALL
			SELECT [Metadata_ID] FROM [MeDriAnchor].[DBTable_Shadow] WHERE ISNULL([Metadata_ID], 0) = @Metadata_ID UNION ALL
			SELECT [Metadata_ID] FROM [MeDriAnchor].[DBTableColumn_Shadow] WHERE ISNULL([Metadata_ID], 0) = @Metadata_ID UNION ALL
			SELECT [Metadata_ID] FROM [MeDriAnchor].[DBTableTie_Shadow] WHERE ISNULL([Metadata_ID], 0) = @Metadata_ID UNION ALL
			SELECT [Metadata_ID] FROM [MeDriAnchor].[DBTableTieColumns_Shadow] WHERE ISNULL([Metadata_ID], 0) = @Metadata_ID
			))
	BEGIN
		SET @MetadataChanged = 1;
	END
	ELSE
	BEGIN
		SET @MetadataChanged = 0;
	END

	RETURN @MetadataChanged;

END