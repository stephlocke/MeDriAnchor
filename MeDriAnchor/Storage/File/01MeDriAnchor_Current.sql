
ALTER DATABASE [$(DatabaseName)]
ADD FILE
(
    NAME = [MeDriAnchor_Current],
    FILENAME = '$(DefaultDataPath)$(DefaultFilePrefix)_Current.ndf',
    SIZE = 1GB,
    FILEGROWTH = 256MB
)
TO FILEGROUP [MeDriAnchor_Current];
GO