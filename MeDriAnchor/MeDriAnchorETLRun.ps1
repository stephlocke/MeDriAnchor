#$servercredential = new-object System.Management.Automation.PSCredential("dwhacct", ("dwhpassword"|  ConvertTo-SecureString -asPlainText -Force))
#$serverContext = New-AzureSqlDatabaseServerContext -ServerName "DummyDWHdest" -Credential $serverCredential
#$db = Get-AzureSqlDatabase $serverContext –DatabaseName “DWH”
#$S1 = Get-AzureSqlDatabaseServiceObjective $serverContext -ServiceObjectiveName "S1"

param
(
  [string]$medrianchordbname,
  [string]$medrianchordbserver,
  [string]$environment,
  [Byte]$debug
)

function runCROWETL($medrianchordbname, $medrianchordbserver, $environment, $debug)
{

	[System.Reflection.Assembly]::loadwithpartialname("System.Data") >> $null;
	$SqlCmdEventAlert = New-Object System.Data.SqlClient.SqlCommand;

	write-host "START" -ForegroundColor Yellow;

	#########################################################################################################################
	## STEP 1: CHECK THAT WE ARE RUNNING AS THE CORRECT USER
	#########################################################################################################################

	write-host "Checking for the correct running user...." -ForegroundColor Yellow;

	$runninguser = [Environment]::UserName
	if ($runninguser.CompareTo("dwhacct") = 0)
	{
		$errorMsg = "This must be run as the dwhacct windows user. Stopping.";
		throw $errorMsg;
	}

	#########################################################################################################################
	## STEP 2: CHECK FOR CONTROL DB CONNECTIVITY
	#########################################################################################################################

	write-host "Connecting to MeDriAnchor DB...." -ForegroundColor Yellow;

	# connect to the MeDriAnchor database and run the ETL for the given environment
	try
	{
		$sqlConnectionMeDriAnchorDB = new-object System.Data.SqlClient.SqlConnection;
		$sqlConnectionMeDriAnchorDB.ConnectionString = "Persist Security Info=False;Integrated Security=true;Initial Catalog=" + $medrianchordbname + ";server=" + $medrianchordbserver + ";";
		$sqlConnectionMeDriAnchorDB.Open();
	}
	catch
	{
		# throw a fatal error if we can't connect to do anything
		$errorMsg = "Cannot connect to the control database " + $medrianchordbname + " on server " + $medrianchordbserver + ". Error: " + $_.Exception.ToString();
		throw $errorMsg;
	}

	#########################################################################################################################
	## STEP 3: VALIDATE THE ENVIRONMENT
	#########################################################################################################################

	write-host "Obtaining environment id...." -ForegroundColor Yellow;

	try
	{

		# get the environment id
		$SqlCmdEnv = New-Object System.Data.SqlClient.SqlCommand;
		$SqlCmdEnv.CommandText = "SELECT [Environment_ID] FROM [MeDriAnchor].[Environment] WHERE [EnvironmentName] = '" + $environment + "';";
		$SqlCmdEnv.Connection = $sqlConnectionMeDriAnchorDB;
		$environmentid = $SqlCmdEnv.ExecuteScalar();
	
		# check that the environment id is valid - i.e. we have a positive number returned
		if (!$environmentid)
		{
			# throw an error if we can't get an environment
			throw;
		}

	}
	catch
	{
		# throw a fatal error if we can't get an environment id
		$errorMsg = "Cannot get an Environment Id for environment " + $environment + ". Please check the input variable. Error: " + $_.Exception.ToString();
		throw $errorMsg;
	}

	write-host "Obtaining environment schema...." -ForegroundColor Yellow;

	# get the schema name to use
	$SqlCmdEnvS = New-Object System.Data.SqlClient.SqlCommand;
	$SqlCmdEnvS.CommandText = "SELECT [MeDriAnchor].[fnGetEnvironmentSchema](" + $environmentid + ");";
	$SqlCmdEnvS.Connection = $sqlConnectionMeDriAnchorDB;
	$environmentschema = $SqlCmdEnvS.ExecuteScalar();
	
	# check that the environment id is valid - i.e. we have a value returned
	if (!$environmentschema)
	{
		# throw a fatal error if we can't get an environment id
		$errorMsg = "Cannot get an Environment Schema for environment " + $environment + ". Please check the input variable";
		throw $errorMsg;
	}

	#########################################################################################################################
	## STEP 4: INITITATE A BATCH
	#########################################################################################################################

	write-host "Initiating batch...." -ForegroundColor Yellow;

	try
	{
		# set the batch date
		[DateTime]$batchDate = Get-Date -format f;

		$SqlCmdMaintNR = New-Object System.Data.SqlClient.SqlCommand;
		$SqlCmdMaintNR.CommandText = "SET NUMERIC_ROUNDABORT OFF;";
		$SqlCmdMaintNR.Connection = $sqlConnectionMeDriAnchorDB;
		$SqlCmdMaintNR.ExecuteScalar();

		$SqlCmdETLBatch = New-Object System.Data.SqlClient.SqlCommand("[MeDriAnchor].[amsp_ETLSQL_InitiateBatch]", $sqlConnectionMeDriAnchorDB);
		$SqlCmdETLBatch.CommandType = [System.Data.CommandType]'StoredProcedure'
		$SqlCmdETLBatch.CommandTimeout = 600;

		# input parameters
		$SqlCmdETLBatch.Parameters.Add("@BatchDate", [System.Data.SqlDbType]"DateTime") >> $null;
		$SqlCmdETLBatch.Parameters["@BatchDate"].Value = [DateTime]$batchDate;

		$SqlCmdETLBatch.Parameters.Add("@Environment_ID", [System.Data.SqlDbType]"SmallInt") >> $null;
		$SqlCmdETLBatch.Parameters["@Environment_ID"].Value = [Int32]$environmentid;

		$SqlCmdETLBatch.Parameters.Add("@Debug", [System.Data.SqlDbType]"Bit") >> $null; 
		$SqlCmdETLBatch.Parameters["@Debug"].Value = [Byte]$debug;

		# output parameters
		$outParameterBatch = new-object System.Data.SqlClient.SqlParameter;
		$outParameterBatch.ParameterName = "@MetadataChanged";
		$outParameterBatch.Direction = [System.Data.ParameterDirection]"Output";
		$outParameterBatch.SqlDbType = [System.Data.SqlDbType ]"Bit";
		$SqlCmdETLBatch.Parameters.Add($outParameterBatch) >> $null;

		$outParameterBatch = new-object System.Data.SqlClient.SqlParameter;
		$outParameterBatch.ParameterName = "@ETLRun_ID";
		$outParameterBatch.Direction = [System.Data.ParameterDirection]"Output";
		$outParameterBatch.SqlDbType = [System.Data.SqlDbType ]"BigInt";
		$SqlCmdETLBatch.Parameters.Add($outParameterBatch) >> $null;

		$outParameterBatch = new-object System.Data.SqlClient.SqlParameter;
		$outParameterBatch.ParameterName = "@Metadata_ID";
		$outParameterBatch.Direction = [System.Data.ParameterDirection]"Output";
		$outParameterBatch.SqlDbType = [System.Data.SqlDbType ]"BigInt";
		$SqlCmdETLBatch.Parameters.Add($outParameterBatch) >> $null;

		$outParameterBatch = new-object System.Data.SqlClient.SqlParameter;
		$outParameterBatch.ParameterName = "@Batch_ID";
		$outParameterBatch.Direction = [System.Data.ParameterDirection]"Output";
		$outParameterBatch.SqlDbType = [System.Data.SqlDbType ]"BigInt";
		$SqlCmdETLBatch.Parameters.Add($outParameterBatch) >> $null;

		$outParameterBatch = new-object System.Data.SqlClient.SqlParameter;
		$outParameterBatch.ParameterName = "@BatchDate_Previous";
		$outParameterBatch.Direction = [System.Data.ParameterDirection]"Output";
		$outParameterBatch.SqlDbType = [System.Data.SqlDbType ]"DateTime";
		$SqlCmdETLBatch.Parameters.Add($outParameterBatch) >> $null;

		$outParameterBatch = new-object System.Data.SqlClient.SqlParameter;
		$outParameterBatch.ParameterName = "@Batch_ID_Previous";
		$outParameterBatch.Direction = [System.Data.ParameterDirection]"Output";
		$outParameterBatch.SqlDbType = [System.Data.SqlDbType ]"BigInt";
		$SqlCmdETLBatch.Parameters.Add($outParameterBatch) >> $null;

		# generate the ETL procs
		$result = $SqlCmdETLBatch.ExecuteNonQuery();

		# get the output parameters
		$metadataChanged = $SqlCmdETLBatch.Parameters["@MetadataChanged"].Value;
		$etlrunid = $SqlCmdETLBatch.Parameters["@ETLRun_ID"].Value;
		$metadataid = $SqlCmdETLBatch.Parameters["@Metadata_ID"].Value;
		$batchid = $SqlCmdETLBatch.Parameters["@Batch_ID"].Value;
		$batchprevdate = $SqlCmdETLBatch.Parameters["@BatchDate_Previous"].Value;
		$batchprevid = $SqlCmdETLBatch.Parameters["@Batch_ID_Previous"].Value;

		$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Batch initiated');";
		$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
		$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

	}
	catch
	{
		# throw a fatal error if we can't initiate a batch
		$errorMsg = "Error running the amsp_ETLSQL_InitiateBatch procedure. Error: " + $_.Exception.ToString();
		throw $errorMsg;
	}

   write-host "Initiated batch...." -ForegroundColor Yellow;

	#########################################################################################################################
	## STEP 5: IF THE METADATA HAS CHANGED THEN ADJUST THE DWH AND BUILD THE NEW ETL
	#########################################################################################################################

	if ($metadataChanged -eq 1) # only do if we have changed metadata
	{

		# log an alert
		$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Metadata change identified');";
		$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
		$SqlCmdEventAlert.ExecuteNonQuery() >> $null;


		write-host "Obtaining DWH connection...." -ForegroundColor Yellow;

		# we have connectivity and an environment, so get the DWH connection string
		$SqlCmdDWHConn = New-Object System.Data.SqlClient.SqlCommand;
		$SqlCmdDWHConn.CommandText = "SELECT [MeDriAnchor].[fnGetDWHConnectionString](" + $environmentid + ");";
		$SqlCmdDWHConn.Connection = $sqlConnectionMeDriAnchorDB;
		$dwhconnstring = $SqlCmdDWHConn.ExecuteScalar();

		#########################################################################################################################
		## STEP 5.1: GENERATE THE ANCHOR XML
		#########################################################################################################################

		write-host "Generating Anchor XML...." -ForegroundColor Yellow;

		try
		{

			# generate the anchor xml and save it into a file
			$SqlCmdXml = New-Object System.Data.SqlClient.SqlCommand;
			$SqlCmdXml.CommandText = "SELECT [MeDriAnchor].[fnGetAnchorXML](" + $environmentid.ToString() + ");";
			$SqlCmdXml.Connection = $sqlConnectionMeDriAnchorDB;
			[Xml]$xml = $SqlCmdXml.ExecuteScalar();
			$xml.Save("C:\anchormodeler\0.98\LatestAnchorXML.xml");

			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Generated Anchor XML');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

		}
		catch
		{
			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 5, 'Failed to generated Anchor XML');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

			$errorMsg = "Failed to generate Anchor XML. Error: " + $_.Exception.ToString();
			throw $errorMsg;
		}

		#########################################################################################################################
		## STEP 5.2: SISULATE
		#########################################################################################################################

		# Run the XML through the sisulator and run the output over the DWH database

		write-host "Sisulating...." -ForegroundColor Yellow;

		# sisulate
		try
		{
			cd C:\anchormodeler\0.98
			cscript.exe "Sisulator.js" //nologo -x "LatestAnchorXML.xml" -m Anchor -d "SQLServer_uni.directive" -o "LatestDWHSQL.sql";

			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Sisulated Anchor XML');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;
		}
		catch
		{
			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Failed to sisulated Anchor XML');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

			# throw a fatal error if we can't sisulate
			$errorMsg = "Cannot sisulate the anchor XML. Error: " + $_.Exception.ToString()
			throw $errorMsg;
		}

		#########################################################################################################################
		## STEP 5.3: CONNECT TO THE DWH
		#########################################################################################################################

		write-host "Connecting to the DWH DB...." -ForegroundColor Yellow;

		# can we connect to the DWH
		try
		{
			$sqlConnectionMeDriAnchorDWH = new-object System.Data.SqlClient.SqlConnection;
			$sqlConnectionMeDriAnchorDWH.ConnectionString = $dwhconnstring;
			$sqlConnectionMeDriAnchorDWH.Open();

			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Connected to the DWH');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

		}
		catch
		{
			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 5, 'Cannot connect to the DWH');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

			# throw aDWH fatal error if we can't connect to do anything
			$errorMsg = "Cannot connect to the DWH database. Error: " + $_.Exception.ToString()
			throw $errorMsg;
		}

		#########################################################################################################################
		## STEP 5.4: ADJUST THE DWH
		#########################################################################################################################

		write-host "Running the revised DWH DB SQL...." -ForegroundColor Yellow;

		# we can so see if the anchor sisulated SQL is ok
		$dwhScriptFile = Get-Item 'C:\anchormodeler\0.98\LatestDWHSQL.sql';
		$dwhScript = Get-Content $dwhScriptFile.FullName | Out-String;
		$dwhCreateScriptList = [regex]::Split($dwhScript, 'GO\r\n'); 
		$SqlCmdSIS = New-Object System.Data.SqlClient.SqlCommand;
		$SqlCmdSIS.Connection = $sqlConnectionMeDriAnchorDWH;
		[System.Data.SqlClient.SqlTransaction]$dwhSISTransaction = $sqlConnectionMeDriAnchorDWH.BeginTransaction("DWHSisulator");
		$SqlCmdSIS.Transaction = $dwhSISTransaction;

		# first add the schema record
		$SqlCmdSIS.CommandText = 'INSERT INTO [' + $environmentschema + '].[_Schema]([activation], [schema]) VALUES (GETDATE(), ''' + $xml.InnerXml + ''');';
		$SqlCmdSIS.CommandTimeout = 600;
		$SqlCmdSIS.ExecuteNonQuery() >> $null;
  
		foreach ($cSL in $dwhCreateScriptList)
		{ 
			try
			{
				$SqlCmdSIS.CommandText = $cSL;
				$SqlCmdSIS.ExecuteNonQuery() >> $null;
			}
			catch
			{
				$dwhSISTransaction.Rollback();
				throw $_.Exception;
			}
		}
		$dwhSISTransaction.Commit();
		$sqlConnectionMeDriAnchorDWH.Close();

		$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'DWH updated');";
		$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
		$SqlCmdEventAlert.ExecuteNonQuery() >> $null;


		#########################################################################################################################
		## STEP 5.5: ADJUST THE DWH
		#########################################################################################################################

		write-host "Generating DWH object view...." -ForegroundColor Yellow;
	
		try
		{
			$SqlCmdMaint1 = New-Object System.Data.SqlClient.SqlCommand("[MeDriAnchor].[sspDropDWHObjectView]", $sqlConnectionMeDriAnchorDB);
			$SqlCmdMaint1.CommandType = [System.Data.CommandType]'StoredProcedure'
			$SqlCmdMaint1.Parameters.Add("@Environment_ID", [System.Data.SqlDbType]"SmallInt") >> $null;
			$SqlCmdMaint1.Parameters["@Environment_ID"].Value = [Int32]$environmentid;
			$SqlCmdMaint1.Parameters.Add("@Debug", [System.Data.SqlDbType]"Bit") >> $null; 
			$SqlCmdMaint1.Parameters["@Debug"].Value = [Byte]$debug;
			$SqlCmdMaint1.CommandTimeout = 600;
			$result = $SqlCmdMaint1.ExecuteScalar();

			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Dropped DWH object view');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

		}
		catch
		{

			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 5, 'Failed to drop the DWH object view');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

			# throw a fatal error if we can't connect to do anything
			$errorMsg = "Error running the sspDropDWHObjectView procedure. Error: " + $_.Exception.ToString();
			throw $errorMsg;
		}

		try
		{
			# set numeric roundabort off
			$SqlCmdMaintNR = New-Object System.Data.SqlClient.SqlCommand;
			$SqlCmdMaintNR.CommandText = "SET NUMERIC_ROUNDABORT OFF;";
			$SqlCmdMaintNR.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdMaintNR.ExecuteScalar();

			$SqlCmdMaint2 = New-Object System.Data.SqlClient.SqlCommand("[MeDriAnchor].[sspCreateDWHObjectView]", $sqlConnectionMeDriAnchorDB);
			$SqlCmdMaint2.CommandType = [System.Data.CommandType]'StoredProcedure'
			$SqlCmdMaint2.Parameters.Add("@Environment_ID", [System.Data.SqlDbType]"SmallInt") >> $null;
			$SqlCmdMaint2.Parameters["@Environment_ID"].Value = [Int32]$environmentid;
			$SqlCmdMaint2.Parameters.Add("@Debug", [System.Data.SqlDbType]"Bit") >> $null; 
			$SqlCmdMaint2.Parameters["@Debug"].Value = [Byte]$debug;
			$SqlCmdMaint2.CommandTimeout = 600;
			$result = $SqlCmdMaint2.ExecuteScalar();

			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Created the DWH object view');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

		}
		catch
		{
			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 5, 'Failed to create the DWH object view');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

			# throw a fatal error if we can't connect to do anything
			$errorMsg = "Error running the sspCreateDWHObjectView procedure. Error: " + $_.Exception.ToString()
			throw $errorMsg;
		}

		#########################################################################################################################
		## STEP 5.6: GENERATING DWH SYNONYMS
		#########################################################################################################################

		write-host "Generating DWH synonyms...." -ForegroundColor Yellow;

		try
		{
			$SqlCmdMaint3 = New-Object System.Data.SqlClient.SqlCommand("[MeDriAnchor].[sspGenerateDWHSynonyms]", $sqlConnectionMeDriAnchorDB);
			$SqlCmdMaint3.CommandType = [System.Data.CommandType]'StoredProcedure'
			$SqlCmdMaint3.Parameters.Add("@Debug", [System.Data.SqlDbType]"Bit") >> $null;
			$SqlCmdMaint3.Parameters["@Debug"].Value = [Byte]$debug;
			$SqlCmdMaint3.CommandTimeout = 600;
			$result = $SqlCmdMaint3.ExecuteScalar();

			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Created the DWH synonyms');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

		}
		catch
		{
			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 5, 'Failed to create the DWH synonyms');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

			# throw a fatal error if we can't connect to do anything
			$errorMsg = "Error running the sspGenerateDWHSynonyms procedure. Error: " + $_.Exception.ToString()
			throw $errorMsg;
		}
	write-host "Generating DWH source synonyms...." -ForegroundColor Yellow;

        try
        {
            $SqlCmdMaint3 = New-Object System.Data.SqlClient.SqlCommand("[MeDriAnchor].[sspGenerateSourceSynonyms]", $sqlConnectionMeDriAnchorDB);
            $SqlCmdMaint3.CommandType = [System.Data.CommandType]'StoredProcedure'
            $SqlCmdMaint3.Parameters.Add("@Debug", [System.Data.SqlDbType]"Bit") >> $null;
            $SqlCmdMaint3.Parameters["@Debug"].Value = [Byte]$debug;
            $SqlCmdMaint3.CommandTimeout = 600;
            $result = $SqlCmdMaint3.ExecuteScalar();

            $SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Created the DWH source synonyms');";
            $SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
            $SqlCmdEventAlert.ExecuteNonQuery() >> $null;

        }
        catch
        {
            $SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 5, 'Failed to create the DWH source synonyms');";
            $SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
            $SqlCmdEventAlert.ExecuteNonQuery() >> $null;

            # throw a fatal error if we can't connect to do anything
            $errorMsg = "Error running the sspGenerateSourceSynonyms procedure. Error: " + $_.Exception.ToString()
	        throw $errorMsg;
        }
		#########################################################################################################################
		## STEP 5.7: GENERATING DWH INDEXES
		#########################################################################################################################

		write-host "Generating DWH indexes...." -ForegroundColor Yellow;

		try
		{
			$sqlConnectionMeDriAnchorDWH.ConnectionString = $dwhconnstring;
			$sqlConnectionMeDriAnchorDWH.Open();

			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Connected to the DWH database');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

		}
		catch
		{
			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Cannot connect to the DWH database');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

			# throw aDWH fatal error if we can't connect to do anything
			$errorMsg = "Cannot connect to the DWH database. Error: " + $_.Exception.ToString()
			throw $errorMsg;
		}

		# connect to the DWH database and run the necessary procedures there
		try
		{
			$SqlCmdDWHIndexes = New-Object System.Data.SqlClient.SqlCommand("[dbo].[sspGenerateDWHIndexes]", $sqlConnectionMeDriAnchorDWH);
			$SqlCmdDWHIndexes.CommandType = [System.Data.CommandType]'StoredProcedure'
			$SqlCmdDWHIndexes.Parameters.Add("@metadataPrefix", [System.Data.SqlDbType]"NVarChar", 100) >> $null;
			$SqlCmdDWHIndexes.Parameters["@metadataPrefix"].Value = [String]"Batch";
			$SqlCmdDWHIndexes.CommandTimeout = 600;
			$result = $SqlCmdDWHIndexes.ExecuteScalar();

			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Generated the DWH indexes');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

		}
		catch
		{
			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 5, 'Failed to generate the DWH indexes');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

			# throw a fatal error if we can't do this
			$errorMsg = "Error running the sspGenerateDWHIndexes procedure. Error: " + $_.Exception.ToString();
			throw $errorMsg;
		}

		#########################################################################################################################
		## STEP 5.8: DELETING DWH TRIGGERS
		#########################################################################################################################

		write-host "Deleting DWH triggers...." -ForegroundColor Yellow;

		try
		{
			$SqlCmdDWHTriggers = New-Object System.Data.SqlClient.SqlCommand("[dbo].[sspDropAllTriggers]", $sqlConnectionMeDriAnchorDWH);
			$SqlCmdDWHTriggers.CommandType = [System.Data.CommandType]'StoredProcedure'
			$SqlCmdDWHTriggers.CommandTimeout = 300;
			$result = $SqlCmdDWHTriggers.ExecuteScalar();

			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Deleted the DWH triggers');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;
		}
		catch
		{
			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 5, 'Failed to delete the DWH triggers');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

			# throw a fatal error if we can't do this
			$errorMsg = "Error running the sspDropAllTriggers procedure. Error: " + $_.Exception.ToString();
			throw $errorMsg;
		}
		$sqlConnectionMeDriAnchorDWH.Close();

		#########################################################################################################################
		## STEP 5.9: GENERATE THE METADATA MAP
		#########################################################################################################################

		try
		{
			$SqlCmdETLMetaMap = New-Object System.Data.SqlClient.SqlCommand("[MeDriAnchor].[amsp_ETLSQL_GenerateMetadataMap]", $sqlConnectionMeDriAnchorDB);
			$SqlCmdETLMetaMap.CommandType = [System.Data.CommandType]'StoredProcedure'
			$SqlCmdETLMetaMap.CommandTimeout = 0;

			# input parameters
			$SqlCmdETLMetaMap.Parameters.Add("@Batch_ID", [System.Data.SqlDbType]"BigInt") >> $null; 
			$SqlCmdETLMetaMap.Parameters["@Batch_ID"].Value = $batchid;

			$SqlCmdETLMetaMap.Parameters.Add("@Metadata_ID", [System.Data.SqlDbType]"BigInt") >> $null; 
			$SqlCmdETLMetaMap.Parameters["@Metadata_ID"].Value = $metadataid;

			$SqlCmdETLMetaMap.Parameters.Add("@Environment_ID", [System.Data.SqlDbType]"SmallInt") >> $null;
			$SqlCmdETLMetaMap.Parameters["@Environment_ID"].Value = [Int32]$environmentid;

			$SqlCmdETLMetaMap.Parameters.Add("@Debug", [System.Data.SqlDbType]"Bit") >> $null; 
			$SqlCmdETLMetaMap.Parameters["@Debug"].Value = [Byte]$debug;

			$result = $SqlCmdETLMetaMap.ExecuteNonQuery();

			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Created metadata map');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;
		}
		catch
		{
			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 5, 'Failed to create metadata map');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

			# throw a fatal error if we can't do this
			$errorMsg = "Failed to create metadata map. Error: " + $_.Exception.ToString();
			throw $errorMsg;
		}

		#########################################################################################################################
		## STEP 5.10: INITIATING ETL PRODUCTION
		#########################################################################################################################

		write-host "Building the ETL procs...." -ForegroundColor Yellow;

		# now initiate the ETL production
		$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Commenced ETL procedure build');";
		$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
		$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

		$SqlCmdMaintNR = New-Object System.Data.SqlClient.SqlCommand;
		$SqlCmdMaintNR.CommandText = "SET NUMERIC_ROUNDABORT OFF;";
		$SqlCmdMaintNR.Connection = $sqlConnectionMeDriAnchorDB;
		$SqlCmdMaintNR.ExecuteScalar();

		#[System.Data.SqlClient.SqlTransaction]$ETLBuildTransaction = $sqlConnectionMeDriAnchorDB.BeginTransaction("ETLBuild");
		$SqlCmdETLGen = New-Object System.Data.SqlClient.SqlCommand("[MeDriAnchor].[amsp_ETLSQL_Generate]", $sqlConnectionMeDriAnchorDB);
		#$SqlCmdETLGen.Transaction = $ETLBuildTransaction;

		try
		{
		
			$SqlCmdETLGen.CommandType = [System.Data.CommandType]'StoredProcedure'
			$SqlCmdETLGen.CommandTimeout = 0;

			# input parameters
			$SqlCmdETLGen.Parameters.Add("@Environment_ID", [System.Data.SqlDbType]"SmallInt") >> $null;
			$SqlCmdETLGen.Parameters["@Environment_ID"].Value = [Int32]$environmentid;

			$SqlCmdETLGen.Parameters.Add("@Debug", [System.Data.SqlDbType]"Bit") >> $null; 
			$SqlCmdETLGen.Parameters["@Debug"].Value = [Byte]$debug;

			$SqlCmdETLGen.Parameters.Add("@ETLRun_ID", [System.Data.SqlDbType]"BigInt") >> $null; 
			$SqlCmdETLGen.Parameters["@ETLRun_ID"].Value = $etlrunid;

			$SqlCmdETLGen.Parameters.Add("@Metadata_ID", [System.Data.SqlDbType]"BigInt") >> $null; 
			$SqlCmdETLGen.Parameters["@Metadata_ID"].Value = $metadataid;

			$SqlCmdETLGen.Parameters.Add("@Batch_ID", [System.Data.SqlDbType]"BigInt") >> $null; 
			$SqlCmdETLGen.Parameters["@Batch_ID"].Value = $batchid;

			# generate the ETL procs
			$result = $SqlCmdETLGen.ExecuteNonQuery();

			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Completed ETL procedure build');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

		}
		catch
		{
			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 5, 'Error during ETL procedure build');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

			# throw a fatal error if we can't connect to do anything
			$errorMsg = "Error running the amsp_ETLSQL_Generate procedure (generate ETL procedures). Error: " + $_.Exception.ToString();
			throw $errorMsg;
		}

		#########################################################################################################################
		## STEP 5.11: GENERATE THE TESTS
		#########################################################################################################################

		write-host "Generating DWH test proc...." -ForegroundColor Yellow;

		# now initiate the ETL production
		$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Commenced DWH test procedure build');";
		$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
		$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

		$SqlCmdDWHTestNR = New-Object System.Data.SqlClient.SqlCommand;
		$SqlCmdDWHTestNR.CommandText = "SET NUMERIC_ROUNDABORT OFF;";
		$SqlCmdDWHTestNR.Connection = $sqlConnectionMeDriAnchorDB;
		$SqlCmdDWHTestNR.ExecuteScalar();

		#[System.Data.SqlClient.SqlTransaction]$ETLBuildTransaction = $sqlConnectionMeDriAnchorDB.BeginTransaction("DWHTest");
		$SqlCmdDWHTestGen = New-Object System.Data.SqlClient.SqlCommand("[MeDriAnchor].[sspCreateDWHTests]", $sqlConnectionMeDriAnchorDB);
		#$SqlCmdDWHTestGen.Transaction = $ETLBuildTransaction;

		try
		{
		
			$SqlCmdDWHTestGen.CommandType = [System.Data.CommandType]'StoredProcedure'
			$SqlCmdDWHTestGen.CommandTimeout = 120;

			# input parameters
			$SqlCmdDWHTestGen.Parameters.Add("@Batch_ID", [System.Data.SqlDbType]"BigInt") >> $null; 
			$SqlCmdDWHTestGen.Parameters["@Batch_ID"].Value = $batchid;

			$SqlCmdDWHTestGen.Parameters.Add("@Metadata_ID", [System.Data.SqlDbType]"BigInt") >> $null; 
			$SqlCmdDWHTestGen.Parameters["@Metadata_ID"].Value = $metadataid;

			$SqlCmdDWHTestGen.Parameters.Add("@Environment_ID", [System.Data.SqlDbType]"SmallInt") >> $null;
			$SqlCmdDWHTestGen.Parameters["@Environment_ID"].Value = [Int32]$environmentid;

			$SqlCmdDWHTestGen.Parameters.Add("@Debug", [System.Data.SqlDbType]"Bit") >> $null; 
			$SqlCmdDWHTestGen.Parameters["@Debug"].Value = [Byte]$debug;

			# generate the ETL procs
			$result = $SqlCmdDWHTestGen.ExecuteNonQuery();

			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Completed DWH test procedure build');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

		}
		catch
		{
			$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 5, 'Error during DWH test procedure build');";
			$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
			$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

			# throw a fatal error if we can't connect to do anything
			$errorMsg = "Error running the sspCreateDWHTests procedure (generate ETL procedures). Error: " + $_.Exception.ToString();
			throw $errorMsg;
		}

	}
	else
	{
		# log an alert
		$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'No metadata change identified. Going straight to ETL run');";
		$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
		$SqlCmdEventAlert.ExecuteNonQuery() >> $null;
	}

	
	#########################################################################################################################
	## STEP 6: LOCAL DATA SYNCH
	#########################################################################################################################

	write-host "Initiating local data synch...." -ForegroundColor Yellow;

	try
	{

		$SqlCmdSynchNR = New-Object System.Data.SqlClient.SqlCommand;
		$SqlCmdSynchNR.CommandText = "SET NUMERIC_ROUNDABORT OFF;";
		$SqlCmdSynchNR.Connection = $sqlConnectionMeDriAnchorDB;
		$SqlCmdSynchNR.ExecuteScalar();

		
		$SqlCmdSynchNR = New-Object System.Data.SqlClient.SqlCommand;
		$SqlCmdSynchNR.CommandText = "SET QUOTED_IDENTIFIER ON;";
		$SqlCmdSynchNR.Connection = $sqlConnectionMeDriAnchorDB;
		$SqlCmdSynchNR.ExecuteScalar();

		$SqlCmdETLSynch = New-Object System.Data.SqlClient.SqlCommand("[MeDriAnchor].[sspSynchLocalLookups]", $sqlConnectionMeDriAnchorDB);
		$SqlCmdETLSynch.CommandType = [System.Data.CommandType]'StoredProcedure'
		$SqlCmdETLSynch.CommandTimeout = 600;

		# generate the ETL procs
		$result = $SqlCmdETLSynch.ExecuteNonQuery();

		$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Local data synched');";
		$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
		$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

	}
	catch
	{
		# throw a fatal error if we can't initiate a batch
		$errorMsg = "Error running the sspSynchLocalLookups procedure. Error: " + $_.Exception.ToString();
		throw $errorMsg;
	}

	write-host "Completed local data synch...." -ForegroundColor Yellow;


	#########################################################################################################################
	## STEP 7: ETL RUN
	#########################################################################################################################

	write-host "Commencing ETL run loop...." -ForegroundColor Yellow;

	$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Commencing ETL run');";
	$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
	$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

	$startDate = Get-Date -format f;
	write-host "Started: " $startDate.ToString();

	# check if all server involved are online and ready for us to pull data from
	try
	{
		$SqlCmdConn = New-Object System.Data.SqlClient.SqlCommand;
		$SqlCmdConn.CommandText = "SELECT [AllAlive] FROM [MeDriAnchor].[vConnectivity];";
		$SqlCmdConn.Connection = $sqlConnectionMeDriAnchorDB;
		[byte]$allalive = $SqlCmdConn.ExecuteScalar();
	}
	catch
	{
		$errorMsg = "One or more of the linked servers needed to pull the data is offline. Aborting ETL run. Error: " + $_.Exception.Message;
		$SqlCmdConn.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 5, 'One or more of the linked servers needed to pull the data is offline. Aborting ETL run');";
		$SqlCmdConn.ExecuteNonQuery() >> $null;
		throw $errorMsg;
	}

	# release the database connection
	$sqlConnectionMeDriAnchorDB.Close();

	if ($allalive)
	{

		# If successfull, drop into a loop running the procedures one at a time in their own transaction
		# to account for transient Azure connection/VPN errors, we try three times in a loop
		$etlRunRetry = 0;
		$etlRunSuccess = $false;

		# cache a command stub to save the pain of recreating it for each execution (all ETL procs have the same parameters)
		$SqlCmdETLRun = New-Object System.Data.SqlClient.SqlCommand
		$SqlCmdETLRun.CommandType = [System.Data.CommandType]'StoredProcedure'
		$SqlCmdETLRun.CommandTimeout = 90;

		# input parameters
		$paramRunBatchID = $SqlCmdETLRun.Parameters.Add("@Batch_ID", [System.Data.SqlDbType]"BigInt");
		$paramRunBatchID.Value = $batchid;
		$paramRunBatchDate = $SqlCmdETLRun.Parameters.Add("@BatchDate", [System.Data.SqlDbType]"DateTime");
		$paramRunBatchDate.Value = $batchDate;
		$paramRunBatchPrev = $SqlCmdETLRun.Parameters.Add("@PreviousBatchDate", [System.Data.SqlDbType]"DateTime");
		$paramRunBatchPrev.Value = $batchprevdate;
		$paramRunEnvironmentID = $SqlCmdETLRun.Parameters.Add("@Environment_ID", [System.Data.SqlDbType]"SmallInt");
		$paramRunEnvironmentID.Value = $environmentid;
		$paramRunMetadataID = $SqlCmdETLRun.Parameters.Add("@Metadata_ID", [System.Data.SqlDbType]"BigInt");
		$paramRunMetadataID.Value = $metadataid;

		do
		{
			try
			{

				# open a connection
				try
				{
					$sqlConnectionMeDriAnchorDB.ConnectionString = "Persist Security Info=False;Integrated Security=true;Initial Catalog=" + $medrianchordbname + ";server=" + $medrianchordbserver + ";";
					$sqlConnectionMeDriAnchorDB.Open();
				}
				catch
				{
					# throw a fatal error if we can't connect to do anything
					$errorMsg = "Cannot connect to the control database " + $medrianchordbname + " on server " + $medrianchordbserver + ". Error: " + $_.Exception.ToString();
					throw $errorMsg;
				}

				# get the procs to run (in order)
				$scETLRun = $sqlConnectionMeDriAnchorDB.CreateCommand();
				$scETLRun.CommandText = "SELECT [SPName] FROM [MeDriAnchor].[ETLRunOrder] WHERE [ETLRun_ID] = " + $etlrunid + " ORDER BY [SPOrder];";
				$dataAdapterETLRun = new-object System.Data.SqlClient.SqlDataAdapter $SqlCommand;
				$dsETLRun = new-object System.Data.Dataset;
				$dataAdapterETLRun.SelectCommand = $scETLRun;
				$dataAdapterETLRun.Fill($dsETLRun) | Out-Null;
				$dtETLRun = new-object "System.Data.DataTable" "ETLProcs";
				$dtETLRun = $dsETLRun.Tables[0];
				[int]$runResult = 0;
				# release the database connection
				$sqlConnectionMeDriAnchorDB.Close();

				# initially flag the run as a success
				$etlRunSuccess = $true;
	 
				$dtETLRun | FOREACH-OBJECT {
					
					# run the proc
					$etlProcCurrentRetry = 0;
					$etlProcSuccess = $false;
					do
					{
				
						$SqlCmdETLRun.CommandText = $_.SPName;
						try
						{

							# open a connection
							try
							{
								$sqlConnectionMeDriAnchorDB.ConnectionString = "Persist Security Info=False;Integrated Security=true;Initial Catalog=" + $medrianchordbname + ";server=" + $medrianchordbserver + ";";
								$sqlConnectionMeDriAnchorDB.Open();
							}
							catch
							{
								# throw a fatal error if we can't connect to do anything
								$errorMsg = "Cannot connect to the control database " + $medrianchordbname + " on server " + $medrianchordbserver + ". Error: " + $_.Exception.ToString();
								throw $errorMsg;
							}

							$SqlCmdETLRun.Connection = $sqlConnectionMeDriAnchorDB;
							$SqlCmdETLRun.ExecuteNonQuery() >> $null;
							$runResult = $SqlCmdETLRun.Parameters["@ReturnValue"].Value;
							$sqlConnectionMeDriAnchorDB.Close();

							# Write-Host $runResult;
						
							# flag the proc run as successfull
							$etlProcSuccess = $true;
						}
						catch
						{
							# close the connection if it is open
							if ($sqlConnectionMeDriAnchorDB.State -eq 'Open')
							{
								$sqlConnectionMeDriAnchorDB.Close();
							}


							if ($etlProcCurrentRetry -gt 3)
							{
								# tried three times but with no luck
								# log a message (is done in the SP)

								# Write-Host $_.Exception;
						
								# flag as success so we can move onto the next procedure
								$etlProcSuccess = $true;
							}
							else
							{
								# short pause before trying again
								Start-Sleep -s 1;
							}
							$etlProcCurrentRetry = $etlProcCurrentRetry + 1;  
						
						}
					} 
					while (!$etlProcSuccess);
				};
			}
			catch
			{
				# close the connection if it is open
				if ($sqlConnectionMeDriAnchorDB.State -eq 'Open')
				{
					$sqlConnectionMeDriAnchorDB.Close();
				}

				$errorMsg = "Cannot obtain the list of ETL procs to run. Error: " + $_.Exception.ToString()
				if ($etlRunRetry -gt 3)
				{
					# tried three times but with no luck
					throw $errorMsg
				}
				else
				{
					# short pause before trying again
					Start-Sleep -s 1;
				}
				$etlRunRetry = $etlRunRetry + 1;
			}
		} 
		while (!$etlRunSuccess);

	}

	# open a connection
	try
	{
		$sqlConnectionMeDriAnchorDB.ConnectionString = "Persist Security Info=False;Integrated Security=true;Initial Catalog=" + $medrianchordbname + ";server=" + $medrianchordbserver + ";";
		$sqlConnectionMeDriAnchorDB.Open();
	}
	catch
	{
		# throw a fatal error if we can't connect to do anything
		$errorMsg = "Cannot connect to the control database " + $medrianchordbname + " on server " + $medrianchordbserver + ". Error: " + $_.Exception.ToString();
		throw $errorMsg;
	}

	$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Completed ETL run');";
	$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
	$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

	$endDate = Get-Date -format f;
	write-host "Ended: " $endDate.ToString();

	write-host "Completed ETL run loop...." -ForegroundColor Yellow

	#########################################################################################################################
	## STEP 8: RUN TESTS
	#########################################################################################################################

	write-host "Running tests...." -ForegroundColor Yellow;

	$SqlCmdSynchNR = New-Object System.Data.SqlClient.SqlCommand;
	$SqlCmdSynchNR.CommandText = "SET QUOTED_IDENTIFIER ON;";
	$SqlCmdSynchNR.Connection = $sqlConnectionMeDriAnchorDB;
	$SqlCmdSynchNR.ExecuteScalar();

	$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Started running tests');";
	$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
	$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

	[string]$TestSP = "[" + $environmentschema + "].[amsp_TEST_DWH_Run]";

	try
	{
		$SqlRunTests = New-Object System.Data.SqlClient.SqlCommand($TestSP, $sqlConnectionMeDriAnchorDB);
		$SqlRunTests.CommandType = [System.Data.CommandType]'StoredProcedure';
		$SqlRunTests.CommandTimeout = 600;
		$SqlRunTests.Parameters.Add("@Batch_ID", [System.Data.SqlDbType]"BigInt") >> $null;
		$SqlRunTests.Parameters["@Batch_ID"].Value = $batchid;
		$result = $SqlRunTests.ExecuteNonQuery();
	}
	catch
	{
		# throw an error if we can't run the tests
		$errorMsg = "Cannot run the DWH tests. Error: " + $_.Exception.ToString();
		throw $errorMsg;
	}

	$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Completed running tests');";
	$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
	$SqlCmdEventAlert.ExecuteNonQuery() >> $null;

	#########################################################################################################################
	## STEP 9: ASCERTAINING BATCH SUCCESS
	#########################################################################################################################

	write-host "Ascertaining batch success...." -ForegroundColor Yellow;

	$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Ascertaining batch success');";
	$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
	$SqlCmdEventAlert.ExecuteNonQuery() >> $null;
	
	$SqlCmdBatchSuccess = New-Object System.Data.SqlClient.SqlCommand("[MeDriAnchor].[sspFlagBatchStatus]", $sqlConnectionMeDriAnchorDB);
	$SqlCmdBatchSuccess.CommandType = [System.Data.CommandType]'StoredProcedure'
	$SqlCmdBatchSuccess.Parameters.Add("@Batch_ID", [System.Data.SqlDbType]"BigInt") >> $null;
	$SqlCmdBatchSuccess.Parameters["@Batch_ID"].Value = $batchid;
	$result = $SqlCmdBatchSuccess.ExecuteScalar();

	$SqlCmdEventAlert.CommandText = "INSERT INTO [MeDriAnchor].[EventAlerts]([Batch_ID], [SeverityID], [AlertMessage]) VALUES (" + $batchid.ToString() + ", 1, 'Ascertained batch success');";
	$SqlCmdEventAlert.Connection = $sqlConnectionMeDriAnchorDB;
	$SqlCmdEventAlert.ExecuteNonQuery() >> $null;
	
	#########################################################################################################################
	## STEP 10: CLOSING CONNECTIONS
	#########################################################################################################################

	write-host "Closing DB connections...." -ForegroundColor Yellow;

	# close the database connection
	$sqlConnectionMeDriAnchorDB.Close();

	write-host "END" -ForegroundColor Yellow;

}

# runCROWETL $medrianchordbname $medrianchordbserver $environment $debug;

runCROWETL "MeDriAnchor" "dummymedrianchordb" "DEVELOPMENT" 0;