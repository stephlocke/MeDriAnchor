
CREATE PROCEDURE [MeDriAnchor].[sspAddDBTest]
(
@TestName NVARCHAR(100),
@TestType NVARCHAR(50)
)
AS
SET NOCOUNT ON;

BEGIN TRAN;

BEGIN TRY

	-- first try an update
	UPDATE [MeDriAnchor].[DBTableColumnTest] SET
		[TestType] = @TestType
	WHERE [TestName] = @TestName;

	-- if nothing to update then insert
	IF (@@ROWCOUNT = 0)
	BEGIN
		INSERT INTO [MeDriAnchor].[DBTableColumnTest]
			(
			[TestType],
			[TestName]
			)
		VALUES
			(
			@TestType,
			@TestName
			);
	END

	COMMIT TRANSACTION;

	RETURN 0;

END TRY

BEGIN CATCH

	DECLARE @ErrorMessage NVARCHAR(4000);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;

	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);

	ROLLBACK TRANSACTION;

	RETURN -1;

END CATCH;