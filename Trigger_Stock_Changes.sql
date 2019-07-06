USE [PROD_DB]
GO
/****** Object:  Trigger [dbo].[RENDELÉS_STÁTUSZ_UPDATE]    Script Date: 2019.02.03. 18:35:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER TRIGGER [dbo].[RENDELÉS_STÁTUSZ_UPDATE]
   ON  [dbo].[RENDELÉS_ÁR_AJÁNLAT]
   AFTER UPDATE 
AS 
BEGIN

	SET NOCOUNT ON;
	
	--Ez a Trigger akkor sül el ha a lenti státuszok változnak
	--Itt változik a készlet mennyisége státuszok szerint

DECLARE @TÖLTŐ_ELÁJÁRÁS_NEVE VARCHAR(50) = 'RENDELÉS_STÁTUSZ_UPDATE - trigger'
DECLARE @BETÖLTŐ_SZEMÉLY VARCHAR(50) = SUSER_SNAME()

	BEGIN TRY 

	EXEC dbo.utils_log_info @TÖLTŐ_ELÁJÁRÁS_NEVE, 'Trigger elindult', @BETÖLTŐ_SZEMÉLY;


		DECLARE @JELEN_STATUSZ varchar(50) = (SELECT UPPER(inserted.RENDELÉS_STÁTUSZ) FROM inserted)	
		DECLARE @TERMÉK_ID as varchar(50)
		DECLARE @JELENLEGI_KÉSZLET as varchar(50) 
		DECLARE @RÉGI_RENDELT_MENNYISÉG as varchar(50)
		DECLARE @RÉGI_VISSZAKÜLDÖTT_MENNYISÉG as varchar(50)
		DECLARE @ÚJ_RENDELT_MENNYISÉG as varchar(50)
		DECLARE @ÚJ_VISSZAKÜLDÖTT_MENNYISÉG as varchar(50)
		DECLARE @IDEIGLENES_EREDMÉNY as varchar(50)
		DECLARE @EREDMÉNY as varchar(50)


		SELECT @TERMÉK_ID = TERMÉK_ID FROM inserted
		SELECT @JELENLEGI_KÉSZLET = JELENLEGI_KÉSZLET FROM KÉSZLET WHERE TERMÉK_ID = @TERMÉK_ID
		SELECT @RÉGI_RENDELT_MENNYISÉG = RENDELT_MENNYISÉG FROM deleted
		SELECT @ÚJ_RENDELT_MENNYISÉG = RENDELT_MENNYISÉG FROM inserted
		SELECT @RÉGI_VISSZAKÜLDÖTT_MENNYISÉG = VISSZAKÜLDÖTT_MENNYISÉG FROM deleted
		SELECT @ÚJ_VISSZAKÜLDÖTT_MENNYISÉG = VISSZAKÜLDÖTT_MENNYISÉG FROM inserted


IF @JELEN_STATUSZ = UPPER('Csomagolva') AND UPDATE(RENDELT_MENNYISÉG) --Ha a csomagolt mennyiség is változik a készlet is változik
	BEGIN

		SELECT @IDEIGLENES_EREDMÉNY = CONVERT(int, @RÉGI_RENDELT_MENNYISÉG) - CONVERT (int, @ÚJ_RENDELT_MENNYISÉG)
		SELECT @EREDMÉNY = CONVERT(int,@JELENLEGI_KÉSZLET) + CONVERT(int, @IDEIGLENES_EREDMÉNY)
	    UPDATE KÉSZLET SET JELENLEGI_KÉSZLET = @EREDMÉNY WHERE TERMÉK_ID = @TERMÉK_ID

	END 
	 
ELSE IF @JELEN_STATUSZ = UPPER('Csomagolva') AND UPDATE(RENDELÉS_STÁTUSZ) --kivonja a készletből a Csomagolt mennyiséget
	BEGIN

		SELECT @EREDMÉNY = CONVERT(int,@JELENLEGI_KÉSZLET) - CONVERT(int, @ÚJ_RENDELT_MENNYISÉG)
	    UPDATE KÉSZLET SET JELENLEGI_KÉSZLET = @EREDMÉNY WHERE TERMÉK_ID = @TERMÉK_ID

	END 
	
ELSE IF  @JELEN_STATUSZ = UPPER('Visszaküldve - jó termék') AND UPDATE(VISSZAKÜLDÖTT_MENNYISÉG) --ha a visszeküldött mennyiség is változik akkor a készlet is változik 
	BEGIN

		SELECT @IDEIGLENES_EREDMÉNY = CONVERT(int, @ÚJ_VISSZAKÜLDÖTT_MENNYISÉG) - CONVERT (int, @RÉGI_VISSZAKÜLDÖTT_MENNYISÉG)
		SELECT @EREDMÉNY = CONVERT(int,@JELENLEGI_KÉSZLET) + CONVERT(int, @IDEIGLENES_EREDMÉNY)
		UPDATE KÉSZLET SET JELENLEGI_KÉSZLET = @EREDMÉNY WHERE TERMÉK_ID = @TERMÉK_ID

	END 
	
ELSE IF @JELEN_STATUSZ = UPPER('Visszaküldve - jó termék') AND UPDATE(RENDELÉS_STÁTUSZ)    --hozzáadja a készlethez visszaküldött termék
	BEGIN

		SELECT @EREDMÉNY = CONVERT(int,@JELENLEGI_KÉSZLET) + CONVERT(int, @ÚJ_VISSZAKÜLDÖTT_MENNYISÉG)
		UPDATE KÉSZLET SET JELENLEGI_KÉSZLET = @EREDMÉNY WHERE TERMÉK_ID = @TERMÉK_ID

	END 

ELSE IF @JELEN_STATUSZ = UPPER('Visszaküldve - hibás termék') AND UPDATE(RENDELÉS_STÁTUSZ) --átrakja a termékeket a HIBÁS_TERMÉK táblába ahol eldől a termék sorsa. (a készlet nem változik majd csak a HIBÁS_TERMÉK táblában)
	BEGIN

		INSERT INTO HIBÁS_TERMÉK (TERMÉK_ID, DARABSZÁM, RENDELÉS_ÁR_AJÁNLAT_ID) VALUES(@TERMÉK_ID, @ÚJ_VISSZAKÜLDÖTT_MENNYISÉG, (SELECT RENDELÉS_ÁR_AJÁNLAT_ID FROM inserted))

	END
 
	EXEC dbo.utils_log_info @TÖLTŐ_ELÁJÁRÁS_NEVE, 'Trigger befejeződött', @BETÖLTŐ_SZEMÉLY

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
