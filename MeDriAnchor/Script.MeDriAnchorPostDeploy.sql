
/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/

:r .\PostDeploy\00RunTodoc.sql

:r .\PostDeploy\01LoadMeDriAnchorDefaultData.sql

:r .\PostDeploy\02LoadMeDriAnchorDefaultServersAndDBs.sql

:r .\PostDeploy\03PopulateMeDriAnchorAGateway.sql

:r .\PostDeploy\05CreateSourceSynonyms.sql

:r .\PostDeploy\06DWHTests.sql





