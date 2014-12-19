param
(
  [string]$medrianchordbname,
  [string]$medrianchordbserver,
  [string]$environment
)

function runDWHMaintenance($medrianchordbname, $medrianchordbserver, $environment)
{

    [System.Reflection.Assembly]::loadwithpartialname("System.Data") >> $null;
    $SqlCmdEventAlert = New-Object System.Data.SqlClient.SqlCommand;

    write-host "START" -ForegroundColor Yellow;

    #########################################################################################################################
    ## STEP 1: CHECK FOR CONTROL DB CONNECTIVITY
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
    ## STEP 2: VALIDATE THE ENVIRONMENT
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

    #########################################################################################################################
    ## STEP 3: GET DWH CONNECTION
    #########################################################################################################################

    write-host "Obtaining DWH connection...." -ForegroundColor Yellow;

    try
    {
        # we have connectivity and an environment, so get the DWH connection string
        $SqlCmdDWHConn = New-Object System.Data.SqlClient.SqlCommand;
        $SqlCmdDWHConn.CommandText = "SELECT [MeDriAnchor].[fnGetDWHConnectionString](" + $environmentid + ");";
        $SqlCmdDWHConn.Connection = $sqlConnectionMeDriAnchorDB;
        $dwhconnstring = $SqlCmdDWHConn.ExecuteScalar();
    }
    catch
    {

        # throw a fatal error if we can't connect to do anything
        $errorMsg = "Error getting the DWH connection. Error: " + $_.Exception.ToString();
        throw $errorMsg;
    }

    $sqlConnectionMeDriAnchorDB.Close();

    #########################################################################################################################
    ## STEP 4: CONNECT TO THE DWH
    #########################################################################################################################

    write-host "Connecting to the DWH DB...." -ForegroundColor Yellow;

    # can we connect to the DWH
    try
    {
        $sqlConnectionMeDriAnchorDWH = new-object System.Data.SqlClient.SqlConnection;
        $sqlConnectionMeDriAnchorDWH.ConnectionString = $dwhconnstring;
        $sqlConnectionMeDriAnchorDWH.Open();
    }
    catch
    {
        # throw aDWH fatal error if we can't connect to do anything
        $errorMsg = "Cannot connect to the DWH database. Error: " + $_.Exception.ToString();
        throw $errorMsg;
    }

    #########################################################################################################################
    ## STEP 5: INDEXES
    #########################################################################################################################

    write-host "Indexes...." -ForegroundColor Yellow;

    try
    {
        $SqlCmdMaint1 = New-Object System.Data.SqlClient.SqlCommand("[dbo].[sspIndexMaintenance]", $sqlConnectionMeDriAnchorDWH);
        $SqlCmdMaint1.CommandType = [System.Data.CommandType]'StoredProcedure'
        $SqlCmdMaint1.CommandTimeout = 0;
        $result = $SqlCmdMaint1.ExecuteScalar();

    }
    catch
    {

        # throw a fatal error if we can't connect to do anything
        $errorMsg = "Error running the sspIndexMaintenance procedure. Error: " + $_.Exception.ToString();
        throw $errorMsg;
    }

    #########################################################################################################################
    ## STEP 6: STATISTICS
    #########################################################################################################################

    write-host "Statistics...." -ForegroundColor Yellow;

    try
    {
        $SqlCmdMaint1 = New-Object System.Data.SqlClient.SqlCommand("[dbo].[sspStatisticsMaintenance]", $sqlConnectionMeDriAnchorDWH);
        $SqlCmdMaint1.CommandType = [System.Data.CommandType]'StoredProcedure'
        $SqlCmdMaint1.CommandTimeout = 0;
        $result = $SqlCmdMaint1.ExecuteScalar();

    }
    catch
    {

        # throw a fatal error if we can't connect to do anything
        $errorMsg = "Error running the sspStatisticsMaintenance procedure. Error: " + $_.Exception.ToString();
        throw $errorMsg;
    }

    $sqlConnectionMeDriAnchorDWH.Close()

    write-host "END" -ForegroundColor Yellow;

}

runDWHMaintenance "MeDriAnchor" "dummymedrianchordb" "DEVELOPMENT"