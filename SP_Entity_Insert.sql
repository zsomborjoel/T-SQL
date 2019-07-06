USE [PROD_DB]
GO

/****** Object:  StoredProcedure [dbo].[usp_entitas_adat_insert]    Script Date: 2019.02.03. 18:32:35 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_entitas_adat_insert]
	@név varchar(255) = NULL,
	@telefonszám varchar(50) = NULL,
	@email varchar(255) = NULL,
	@ország varchar(50) = NULL,
	@irányitószám varchar(50) = NULL,
	@város varchar(50) = NULL,
	@utca varchar(50) = NULL,
	@házszám varchar(50) = NULL,
	@típus varchar(50) = NULL,
	@szegmens varchar(50) = NULL,
	@bankszámlaszám varchar(50) = NULL,
	@adóazonosító varchar(50) = NULL,
	@cégnév varchar(255) = NULL

AS
BEGIN
    SET NOCOUNT ON;


    BEGIN TRY

		--Töltés kezdetének logolása
		DECLARE @TÖLTŐ_ELÁJÁRÁS_NEVE VARCHAR(50) = 'usp_entitas_adat_insert - tárolteljárás'
		DECLARE @BETÖLTŐ_SZEMÉLY VARCHAR(50) = SUSER_SNAME()

		EXEC dbo.utils_log_info @TÖLTŐ_ELÁJÁRÁS_NEVE, 'Betöltés megkezdődött', @BETÖLTŐ_SZEMÉLY;

				DECLARE @entitás_id int, @entitás_szegmens_id int 

				SELECT @entitás_szegmens_id = ENTITÁS_SZEGMENS_ID 
				FROM ENTITÁS_SZEGMENS
				WHERE SZEGMENS_NÉV = @szegmens

				INSERT INTO dbo.ENTITÁS (TELJES_NÉV, ENTITÁS_SZEGMENS_ID) 
				VALUES(@név, @entitás_szegmens_id)
	
				SELECT @entitás_id = ENTITÁS_ID 
				FROM dbo.ENTITÁS 
				WHERE TELJES_NÉV = @név

		EXEC dbo.utils_log_info @TÖLTŐ_ELÁJÁRÁS_NEVE, 'Entitás név betöltődött' , @BETÖLTŐ_SZEMÉLY;

				INSERT INTO dbo.TELEFONSZÁM (TELEFONSZÁM, ENTITÁS_ID) 
				VALUES (@telefonszám, @entitás_id)
		
				INSERT INTO dbo.EMAIL (EMAIL_CÍM, ENTITÁS_ID) 
				VALUES (@email, @entitás_id)
		
				INSERT INTO dbo.CÍM (ENTITÁS_ID, ORSZÁG, IRÁNYITÓSZÁM, VÁROS, UTCA, HÁZSZÁM, TÍPUS) 
				VALUES (@entitás_id, @ország, @irányitószám, @város, @utca, @házszám, @típus)
		
				INSERT INTO dbo.ADÓAZONOSÍTÓ (ENTITÁS_ID, ADÓAZONOSÍTÓ) 
				VALUES(@entitás_id, @adóazonosító)
		
				INSERT INTO dbo.CÉG (ENTITÁS_ID, CÉG_NÉV) 
				VALUES (@entitás_id, @cégnév)
	
				INSERT INTO dbo.BANKSZÁMLA (ENTITÁS_ID, BANKSZÁMLASZÁM) 
				VALUES (@entitás_id, @bankszámlaszám)
	
		EXEC dbo.utils_log_info @TÖLTŐ_ELÁJÁRÁS_NEVE, 'Entitás betöltés befejeződött' , @BETÖLTŐ_SZEMÉLY;

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

    END CATCH;
END;


GO



