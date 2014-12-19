
-- EXTENDED PROPERTIES MIMIC VIEW
CREATE VIEW [MeDriAnchor].[svExtProps]
AS
/*
Emulates the extended properties functionality used by the non-Azure MeDriAnchor
*/
SELECT	'False' AS [HasView],
		'av' AS [ViewNamePrefix],
		'' AS [ViewNamePostfix],
		'True' AS [HasShadowTable],
		'' AS [ShadowTableNamePrefix],
		'_Shadow' AS [ShadowTableNamePostfix],
		'True' AS [MaintenanceMode],
		'MIRROR' AS [ShadowFilegroupPlacement],
		'False' AS [MirrorPartitionScheme],
		'False' AS [HasInsertProc],
		'asp' AS [InsertProcNamePrefix],
		'_Insert' AS [InsertProcNamePostfix],
		'False' AS [HasUpdateProc],
		'asp' AS [UpdateProcNamePrefix],
		'_Update' AS [UpdateProcNamePostfix],
		'False' AS [HasDeleteProc],
		'asp' AS [DeleteProcNamePrefix],
		'_Delete' AS [DeleteProcNamePostfix],
		'False' AS [HasSaveProc],
		'asp' AS [SaveProcNamePrefix],
		'_Save' AS [SaveProcNamePostfix],
		'True' AS [HasInsertTrigger],
		'atr' AS [InsertTriggerNamePrefix],
		'_Insert' AS [InsertTriggerNamePostfix],
		'True' AS [HasUpdateTrigger],
		'atr' AS [UpdateTriggerNamePrefix],
		'_Update' AS [UpdateTriggerNamePostfix],
		'True' AS [HasDeleteTrigger],
		'atr' AS [DeleteTriggerNamePrefix],
		'_Delete' AS [DeleteTriggerNamePostfix],
		'amsp_Knot_' AS [KnotETLProcNamePrefix],
		'amsp_Anchor_' AS [AnchorETLProcNamePrefix],
		'amsp_Attribute_' AS [AttributeETLProcNamePrefix],
		'amsp_Tie_' AS [TieETLProcNamePrefix],
		'_ETLSQL_Run' AS [ETLProcNamePostfix];
