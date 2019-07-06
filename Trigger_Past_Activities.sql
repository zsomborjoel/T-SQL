USE [PROD_DB]
GO
/****** Object:  Trigger [dbo].[RENDELÉS_ÁR_AJÁNLAT_VÁLTOZÁS]    Script Date: 2019.02.03. 18:35:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER TRIGGER [dbo].[RENDELÉS_ÁR_AJÁNLAT_VÁLTOZÁS]
ON [dbo].[RENDELÉS_ÁR_AJÁNLAT]
AFTER INSERT, UPDATE, DELETE
AS

BEGIN
/*
UPDATE
------
Adat bekerül INSERTED, és DELETED táblába

INSERT
------
Adat bekerül az INSERTED táblába

DELETE
------
Adat bekerül a DELETED táblába
*/

DECLARE @TÖLTŐ_ELÁJÁRÁS_NEVE VARCHAR(50) = 'RENDELÉS_ÁR_AJÁNLAT_VÁLTOZÁS - trigger'
DECLARE @BETÖLTŐ_SZEMÉLY VARCHAR(50) = SUSER_SNAME()


	BEGIN TRY 

	EXEC dbo.utils_log_info @TÖLTŐ_ELÁJÁRÁS_NEVE, 'Trigger elindult', @BETÖLTŐ_SZEMÉLY;

--Ha nincs benne a DELETED táblában (Avagy egy INSERT történt)
IF NOT EXISTS  
	(
	 SELECT * FROM Deleted
	)
		--Akkor az új adatsort rakja bele a RÉGI_ÁR táblába
		INSERT INTO dbo.[RÉGI_RENDELÉS_ÁR_AJÁNLAT]
		(
			[RENDELÉS_ID],
			[TERMÉK_ID],
			[RENDELT_MENNYISÉG],
			[ÁR_AJÁNLAT_HUF],
			[ÁR_AJÁNLAT_EURO],
			BETÖLTŐ_SZEMÉLY,
			VALID_ETTŐL
		)
			SELECT
			[RENDELÉS_ID],
			[TERMÉK_ID],
			[RENDELT_MENNYISÉG],
			[ÁR_AJÁNLAT_HUF],
			[ÁR_AJÁNLAT_EURO],
			SUSER_SNAME(),
			GETDATE()
			FROM Inserted
			
 
--Ha nincs benne az INSERTED  táblában (Avagy egy DELETE történt)
ELSE IF NOT EXISTS 
	(
	SELECT * FROM Inserted
	)
		INSERT INTO dbo.[RÉGI_RENDELÉS_ÁR_AJÁNLAT] 
		(
			[RENDELÉS_ID],
			[TERMÉK_ID],
			[RENDELT_MENNYISÉG],
			[ÁR_AJÁNLAT_HUF],
			[ÁR_AJÁNLAT_EURO],
			BETÖLTŐ_SZEMÉLY,
			VALID_ETTŐL
		)
			SELECT
			[RENDELÉS_ID],
			[TERMÉK_ID],
			[RENDELT_MENNYISÉG],
			[ÁR_AJÁNLAT_HUF],
			[ÁR_AJÁNLAT_EURO],
			SUSER_SNAME(),
			GETDATE()
			FROM deleted

	EXEC dbo.utils_log_info @TÖLTŐ_ELÁJÁRÁS_NEVE, 'Trigger befejeződött', @BETÖLTŐ_SZEMÉLY;

	END TRY 

	BEGIN CATCH
	
		-- Print error information. 
		PRINT 'Error ' + CONVERT(varchar(50), ERROR_NUMBER()) +
			  ', Severity ' + CONVERT(varchar(5), ERROR_SEVERITY()) +
			  ', State ' + CONVERT(varchar(5), ERROR_STATE()) + 
			  ', Procedure ' + ISNULL(ERROR_PROCEDURE(), '-') + 
			  ', Line ' + CONVERT(varchar(5), ERROR_LINE());
		PRINT ERROR_MESSAGE();

		DECLARE @SYS_ERROR_NUMBER varchar(50) = ERROR_NUMBER()
		DECLARE @SYS_ERROR_PROCEDURE varchar(50) = ISNULL(ERROR_PROCEDURE(), '-')
		DECLARE @SYS_ERROR_LINE varchar(50) = CONVERT(varchar(5), ERROR_LINE())
		DECLARE @SYS_ERROR_MESSAGE varchar(max) = ERROR_MESSAGE()
		
		EXEC dbo.utils_log_error @TÖLTŐ_ELÁJÁRÁS_NEVE, @SYS_ERROR_NUMBER, @SYS_ERROR_PROCEDURE, @SYS_ERROR_LINE, @SYS_ERROR_MESSAGE, @BETÖLTŐ_SZEMÉLY

    END CATCH

END 
