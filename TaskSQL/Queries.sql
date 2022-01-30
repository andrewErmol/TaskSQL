CREATE DATABASE TaskSQL;
USE TaskSQL;

CREATE TABLE Banks(
	Id INT NOT NULL IDENTITY (1, 1),
	BankName VARCHAR(30) NOT NULL,
	
	PRIMARY KEY(Id)
);

CREATE TABLE Cities(
	Id INT NOT NULL IDENTITY (1, 1),
	City VARCHAR(30) NOT NULL,
	
	PRIMARY KEY(Id)
);

CREATE TABLE BanksCities(
	Id INT NOT NULL IDENTITY (1, 1),
	BankId INT NOT NULL,
	CityId INT NOT NULL,
	
	PRIMARY KEY(Id),
	
	FOREIGN KEY (BankId) REFERENCES Banks(Id),
	FOREIGN KEY (CityId) REFERENCES Cities(Id)
);

CREATE TABLE SocialStatus(
	Id INT NOT NULL IDENTITY (1, 1),
	SocialStatus VARCHAR(15) NOT NULL,
	
	PRIMARY KEY(Id)
);

CREATE TABLE Owners(
	Id INT NOT NULL IDENTITY(1,1),
	SocialStatusId INT NOT NULL,
	OwnerName VARCHAR(30) NOT NULL,
	
	PRIMARY KEY(Id),
	
	FOREIGN KEY (SocialStatusId) REFERENCES SocialStatus(Id)
);

CREATE TABLE Accounts(
	Id INT NOT NULL IDENTITY (1, 1),
	Balance Decimal(18, 2) NOT NULL,
	BankId int NOT NULL,
	OwnerId int NOT NULL,
	
	PRIMARY KEY(id),
	
	FOREIGN KEY (BankId) REFERENCES Banks(Id),
	FOREIGN KEY (OwnerId) REFERENCES Owners(Id)
);

CREATE TABLE Cards(
	AccountId INT NOT NULL,
	CardNumber VARCHAR(16) NOT NULL UNIQUE,
	CardBalance DECIMAL(18, 2) NOT NULL,
	
	PRIMARY KEY(CardNumber),
	
	FOREIGN KEY (AccountId) REFERENCES Accounts(Id)
);

--Filling out the table "Banks"
INSERT INTO Banks(BankName) 
values ('Bank1'),
	('Alfa-bank'), 
	('Belarusbank'), 
	('BPSBank'), 
	('BelAgroPromBank');

--Filling out the table "Cities"
INSERT INTO Cities(City) 
values ('Gomel'), 
	('Minsk'), 
	('Grodno'), 
	('Mogilev'), 
	('Brest'), 
	('Vitebsk');

--Filling out the table "BanksCities"
INSERT INTO BanksCities (BankId, CityId) 
values ('1','2'), 
	('1','1'), ('1','3'), 
	('1','5'), ('2','2'), 
	('2','3'), ('2','5'), 
	('2','1'), ('2','3'), 
	('3','5'), ('3','3'), 
	('3','1'), ('4','2'), 
	('4','4'), ('5','6'), 
	('2','6'), ('5','1');

--Filling out the table "SocialStatus"
INSERT INTO SocialStatus(SocialStatus) 
values ('Pensioner'), 
	('Disabled person'), 
	('And other'),
	('Some_new_status');

--Filling out the table "Owners"
INSERT INTO Owners(SocialStatusId, OwnerName) 
values ('2', 'Ivasenko V.V.'), 
	('3', 'Ermolenko A.A.'), 
	('1', 'Ivanov I.I.'), 
	('3', 'Bokitko A.S.'), 
	('1', 'Pechenkin A.A.');

--Filling out the table "Accounts"
INSERT INTO Accounts(Balance, BankId, OwnerId) 
values ('200.30', '1', '1'), 
	('300.21', '1', '1'), 
	('2015', '3', '2'), 
	('545', '2', '3'), 
	('4125', '4', '5'), 
	('2158', '5', '4');

--Filling out the table "Cards"
INSERT INTO Cards(AccountId, CardNumber, CardBalance) 
values ('6', '1234567891025684', '60.21'), 
	('5', '6589423682354', '125.03'), 
	('4', '5454886452213', '235.06'), 
	('3', '54848303255452', '1225'), 
	('2', '458787933656006', '300.21'), 
	('1', '8759232656552', '125.50'), 
	('6', '87592326565', '200.30');

--Item 1: Output the name of banks that are in the city X
SELECT BankName 
FROM Banks 
	INNER JOIN BanksCities ON Banks.Id = BanksCities.BankId 
	INNER JOIN Cities ON Cities.Id = BanksCities.CityId 
WHERE Cities.City LIKE 'Gomel';

--Item 2: Get a list of cards indicating the name of the owner, balance and the name of the bank
SELECT CardNumber, CardBalance, bankName, OwnerName 
FROM Cards 
	INNER JOIN Accounts ON Cards.AccountId = Accounts.Id 
	INNER JOIN Banks ON Accounts.BankId = Banks.Id 
	INNER JOIN Owners ON Accounts.OwnerId = Owners.Id;

--Item 3: Show a list of bank accounts whose balance does not coincide with the sum of balance on cards. In a separate column, output the difference
SELECT DISTINCT Accounts.Id,
	MAX(Accounts.Balance) 'AccountBalance', 
	SUM(Cards.CardBalance) 'SumOdCardBalanceWithOneAccount', 
	ABS(SUM(Cards.CardBalance) - MAX(Accounts.Balance)) 'Difference'
FROM Accounts 
	INNER JOIN Cards ON Accounts.Id = Cards.AccountId 
GROUP BY (Accounts.Id)
HAVING SUM(Cards.CardBalance) <> MAX(Accounts.Balance)

--Item 4: Output count bank cards for everyone social status with GROUP BY
SELECT SocialStatus, COUNT (Cards.CardNumber) 'CountCards'  
FROM SocialStatus 
	FULL OUTER JOIN Owners ON SocialStatus.Id = Owners.SocialStatusId
	FULL OUTER JOIN Accounts ON Accounts.OwnerId = Owners.Id
	FULL OUTER JOIN Cards ON Accounts.Id = Cards.AccountId
GROUP BY SocialStatus.SocialStatus;

--Item 4: Output count bank cards for everyone social status WITHOUT
SELECT SocialStatus, 
	(SELECT COUNT (Cards.CardNumber)
	FROM Cards
		FULL OUTER JOIN Accounts ON Accounts.Id = Cards.AccountId
		FULL OUTER JOIN Owners ON Owners.Id = Accounts.OwnerId
		WHERE Owners.SocialStatusId = SocialStatus.Id
		) 'CountCards'
FROM SocialStatus

--Item 5: Write Stored Procedure which will add $ 10 to each bank account for a specific status social
GO
CREATE PROCEDURE AddTen @SocStatusId INT
AS 
BEGIN
	Update Accounts SET Balance = Balance + 10 
	FROM Accounts 
		INNER JOIN Owners ON Accounts.OwnerId = Owners.Id 
	WHERE SocialStatusId = @SocStatusId
END;

DECLARE @UpAccountBalanceForSocialStatusId INT = 1
Exec AddTen @UpAccountBalanceForSocialStatusId

--Item 6: Get a list of available funds for each client
SELECT Owners.OwnerName, (SumBalances.SumBalance - SUM(Cards.CardBalance)) AS FreeMoneyOfAccount
FROM (SELECT Owners.Id, SUM (Accounts.Balance) 'SumBalance'
	  FROM Accounts 
		  FULL OUTER JOIN Owners ON Owners.Id = Accounts.OwnerId
	  GROUP BY (Owners.Id)) 
	  AS SumBalances
		FULL OUTER JOIN Owners ON SumBalances.Id = Owners.Id
		FULL OUTER JOIN Accounts ON Accounts.OwnerId = Owners.Id
		FULL OUTER JOIN Cards ON Cards.AccountId = Accounts.Id
	GROUP BY (Owners.OwnerName), (SumBalances.SumBalance)

--Item 7: Write a procedure that will translate money from the account on the card
GO
CREATE PROCEDURE MoneyTransfer 
	@SumForTransfer INT, 
	@AccountIdForTransfer INT, 
	@NumberOfCardForTransfer VARCHAR (16)
AS 
BEGIN
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRY
		BEGIN TRANSACTION MoneyTransfer
			
			DECLARE @AccountBalance DECIMAL(18, 2);
			DECLARE @SumOfCardsBalance DECIMAL(18, 2);
			
			SET @AccountBalance = (
				SELECT Accounts.Balance 
				FROM Accounts 
				WHERE Accounts.Id = @AccountIdForTransfer
			)

			SET @SumOfCardsBalance = (
				SELECT SUM (Cards.CardBalance) 
				FROM Cards 
					INNER JOIN Accounts ON Accounts.Id = Cards.AccountId
				WHERE Accounts.Id = @AccountIdForTransfer
			)

			IF (@AccountBalance - @SumOfCardsBalance >= @SumForTransfer)
			BEGIN
					UPDATE Cards SET CardBalance = CardBalance + @SumForTransfer 
					FROM Cards 
						INNER JOIN Accounts ON Cards.AccountId = Accounts.Id
						INNER JOIN Owners ON Accounts.OwnerId = Owners.Id
					WHERE CardNumber = @NumberOfCardForTransfer AND AccountId = @AccountIdForTransfer
			END

	END TRY

	BEGIN CATCH
		ROLLBACK TRANSACTION
		RAISERROR ('Translation error, try again', 16, 1)
		RETURN
	END CATCH

	COMMIT TRANSACTION
END;

DECLARE @SumForTransfer1 INT = 2200, 
@AccountIdForTransfer1 INT = 6, 
@NumberOfCardForTransfer1 VARCHAR (16) = '1234567891025684'
Exec MoneyTransfer @SumForTransfer1, @AccountIdForTransfer1, @NumberOfCardForTransfer1

DECLARE @SumForTransfer2 INT = 100, 
@AccountIdForTransfer2 INT = 6, 
@NumberOfCardForTransfer2 VARCHAR (16) = '1234567891025684'
Exec MoneyTransfer @SumForTransfer2, @AccountIdForTransfer2, @NumberOfCardForTransfer2

--Item 8: Triggers
GO
CREATE TRIGGER TR_Accounts_SaveNormalBalance
ON Accounts
AFTER UPDATE, INSERT
AS 
BEGIN
	IF Exists
	(
		SELECT SUM 
		(Cards.CardBalance) 
		FROM Cards 
			INNER JOIN Accounts ON Accounts.Id = Cards.AccountId
		GROUP BY (AccountId)
		HAVING SUM (Cards.CardBalance) > MAX (Accounts.Balance)
	)
	ROLLBACK TRANSACTION
END;
GO

CREATE TRIGGER TR_Cards_SaveNormalBalance
ON Cards
AFTER UPDATE, INSERT
AS 
BEGIN
	IF Exists
	(
		SELECT SUM 
		(Cards.CardBalance) 
		FROM Cards 
			INNER JOIN Accounts ON Accounts.Id = Cards.AccountId
		GROUP BY (AccountId)
		HAVING SUM (Cards.CardBalance) > MAX (Accounts.Balance)
	)
		ROLLBACK TRANSACTION
END;

UPDATE Cards SET CardBalance = 300

WHERE AccountId = 1
