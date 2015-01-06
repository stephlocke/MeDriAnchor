--#################################################################################################
-- BEGIN Mail Settings MeDriAnchor Mail
--#################################################################################################

IF NOT EXISTS(SELECT * FROM msdb.dbo.sysmail_profile WHERE  name = 'MeDriAnchor Mail') 
BEGIN
    --CREATE Profile [MeDriAnchor Mail]
	EXECUTE msdb.dbo.sysmail_add_profile_sp
		@profile_name = 'MeDriAnchor Mail',
		@description  = 'MeDriAnchor Mail';
END --IF EXISTS profile
  
IF NOT EXISTS(SELECT * FROM msdb.dbo.sysmail_account WHERE  name = 'MeDriAnchor Mail')
BEGIN
	--CREATE Account [MeDriAnchor Mail]
    EXECUTE msdb.dbo.sysmail_add_account_sp
		@account_name            = 'MeDriAnchor Mail',
		@email_address           = 'MeDriAnchorMail@example.co.uk',
		@display_name            = 'MeDriAnchor Mail',
		@replyto_address         = '',
		@description             = 'MeDriAnchor Mail',
		@mailserver_name         = 'smtp.example.net',
		@mailserver_type         = 'SMTP',
		@port                    = '587',
		@username                = '',
		@password                = '', 
		@use_default_credentials =  0 ,
		@enable_ssl              =  1 ;
END --IF EXISTS  account


  
IF NOT EXISTS(SELECT *
              FROM msdb.dbo.sysmail_profileaccount pa
                INNER JOIN msdb.dbo.sysmail_profile p ON pa.profile_id = p.profile_id
                INNER JOIN msdb.dbo.sysmail_account a ON pa.account_id = a.account_id  
              WHERE p.name = 'MeDriAnchor Mail'
                AND a.name = 'MeDriAnchor Mail') 
BEGIN
    -- Associate Account [MeDriAnchor Mail] to Profile [outlook.office365.com]
    EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
		@profile_name = 'MeDriAnchor Mail',
		@account_name = 'MeDriAnchor Mail',
		@sequence_number = 1 ;
END --IF EXISTS associate accounts to profiles

-- Send a test mail
EXEC msdb.dbo.sp_send_dbmail 
	@profile_name = 'MeDriAnchor Mail', 
	@recipients = 'example@example.co.uk', 
	@subject = '{Subject}', 
	@body = '{Body}', 
	@body_format = 'text';

/*

--Email Status
SELECT SUBSTRING(fail.subject, 1, 25) AS 'Subject'
	,fail.mailitem_id
	,LOG.description
FROM msdb.dbo.sysmail_event_log LOG
INNER JOIN msdb.dbo.sysmail_faileditems fail
	ON fail.mailitem_id = LOG.mailitem_id
WHERE event_type = 'error'

*/

--#################################################################################################
-- Drop Settings For MeDriAnchor Mail
--#################################################################################################
/*
IF EXISTS(SELECT *
            FROM msdb.dbo.sysmail_profileaccount pa
              INNER JOIN msdb.dbo.sysmail_profile p ON pa.profile_id = p.profile_id
              INNER JOIN msdb.dbo.sysmail_account a ON pa.account_id = a.account_id  
            WHERE p.name = 'MeDriAnchorMail'
              AND a.name = 'MeDriAnchorMail')
  BEGIN
    EXECUTE msdb.dbo.sysmail_delete_profileaccount_sp @profile_name = 'MeDriAnchorMail',@account_name = 'MeDriAnchorMail'
  END 
IF EXISTS(SELECT * FROM msdb.dbo.sysmail_account WHERE  name = 'MeDriAnchorMail')
  BEGIN
    EXECUTE msdb.dbo.sysmail_delete_account_sp @account_name = 'MeDriAnchorMail'
  END
IF EXISTS(SELECT * FROM msdb.dbo.sysmail_profile WHERE  name = 'MeDriAnchorMail') 
  BEGIN
    EXECUTE msdb.dbo.sysmail_delete_profile_sp @profile_name = 'MeDriAnchorMail'
  END
*/

/*

SELECT *FROM msdb.dbo.sysmail_account
--SELECT *FROM msdb.dbo.sysmail_configuration
SELECT *FROM msdb.dbo.sysmail_principalprofile
SELECT *FROM msdb.dbo.sysmail_profile
SELECT *FROM msdb.dbo.sysmail_profileaccount
SELECT *FROM msdb.dbo.sysmail_profileaccount

*/