====== Managing the ETL ======

===== Maintaining the scheduled task =====
For the ETL to run on a regular basis, there needs to be a [[https://github.com/stephlocke/MeDriAnchor/blob/master/MeDriAnchor/ETLRunScheduledTask.xml|scheduled task]] that kicks off the [[https://github.com/stephlocke/MeDriAnchor/blob/master/MeDriAnchor/MeDriAnchorETLRun.ps1|PowerShell script]].

This uses a generic service account to run under, in order to prevent expiration issues and so that the user doesn't have to be logged in.

Depending on execution time of the load, the scheduled task schedule may need amending. On top of amending the scheduled task, the Setting ''batchkillafterhours'' should be lengthened as this is also a factor in batch executions.

===== Change email alerts =====
==== From email address ====
This gets changed by dropping the existing SQL Server email profile and recreating with the revised info. Use the [[https://github.com/stephlocke/MeDriAnchor/blob/master/MeDriAnchor/MeDriAnchorMail.sql|Mail Template]]

==== To email address ====
To change the distribution of the alert, alter the [[https://github.com/stephlocke/MeDriAnchor/blob/master/MeDriAnchor/MeDriAnchor/Stored%20Procedures/sspFlagBatchStatus.sql|stored procedure]] ''sspFlagBatchStatus'' and execute it on the MeDriAnchor database.

===== Run a manual load =====
A load can be manually kicked off by running the [[https://github.com/stephlocke/MeDriAnchor/blob/master/MeDriAnchor/MeDriAnchorETLRun.ps1|PowerShell ETL]] script. 

This script can be restricted to only execute when it is running under a specific account to prevent accidental loads being kicked off. To run it in these instances, you'll need to Run As... and have the credentials to hand.

===== Kill a load =====
If you need to stop a load for whatever reason, then you need to Stop the scheduled task. You will also need to set the batch to no longer in progress.
<code>
UPDATE MeDriAnchor.Batch
   SET InProgress = 0
</code>
