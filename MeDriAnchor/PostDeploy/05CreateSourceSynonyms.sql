
USE [MeDriAnchor]
GO

PRINT 'START: Creating source synonyms....';
GO

EXEC [MeDriAnchor].[sspGenerateSourceSynonyms] @Debug = 0;
GO

PRINT 'END: Creating source synonyms....';
GO