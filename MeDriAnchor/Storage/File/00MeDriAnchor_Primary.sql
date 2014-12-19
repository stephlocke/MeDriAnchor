
ALTER DATABASE [$(DatabaseName)]
ADD FILE
(
    NAME = [MeDriAnchor],
    FILENAME = '$(DefaultDataPath)$(DefaultFilePrefix).mdf',
    SIZE = 256MB,
    FILEGROWTH = 64MB
)
TO FILEGROUP [PRIMARY];
GO
