	
--A Tábla, és a script direkt vannak ékezet nélkül írva!!!
--Változók
Declare @JSON varchar(max)
Declare @HUF decimal(30,20)
Declare @DATE date 

--File helyének felvétele
SELECT @JSON = BulkColumn
FROM OPENROWSET (BULK 'C:\Exchange_Rates\CurrencyRates.json', SINGLE_CLOB) as j

--Fileból az árfolyamok betétele változókban
SELECT @HUF = ROUND(CONVERT(decimal(10,2), HUF), 2)
FROM OPENJSON (@JSON,'$.' + 'rates') 
WITH (HUF nvarchar(50))

--Fileból a dátum betétele változóba
SELECT @DATE = date FROM OPENJSON (@JSON)  WITH (date date)

--Végül betöltjük a változókban szereplő adatokat a táblába
INSERT INTO dbo.NAPI_EUR_ARFOLYAM (ARFOLYAM_DATUMA, HUF) VALUES(@DATE, @HUF)