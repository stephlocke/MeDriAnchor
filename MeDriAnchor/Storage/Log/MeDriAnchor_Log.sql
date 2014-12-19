
ALTER DATABASE [$(DatabaseName)]
ADD LOG FILE
(
    NAME = [MeDriAnchor_Log],
    FILENAME = '$(DefaultLogPath)$(DefaultFilePrefix)_Log.ldf',
    SIZE = 256MB,
    FILEGROWTH = 128MB
);