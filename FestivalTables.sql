-- Database: FestivalDB

--ENUMS
CREATE TYPE FestivalStatus AS ENUM ('planiran', 'aktivan', 'zavrsen');
CREATE TYPE WorkshopDifficulty AS ENUM('beginner', 'intermediate', 'advanced');
CREATE TYPE StageLocation AS ENUM ( 
	'main', 
	'side',
	'forest', 
	'beach', 
	'camp', 
	'chill', 
	'indoor', 
	'urban', 
	'electro', 
	'acoustic' 
	); 
CREATE TYPE TicketType AS ENUM ( 'jednodnevna', 
	'festivalska', 
	'VIP', 
	'kamp', 
	'early_bird', 
	'student', 
	'family', 
	'premium' 
);

CREATE TYPE TicketValidity AS ENUM ('dan', 'cijeli_festival');


-- CREATE TABLES 

CREATE TABLE Festivals ( 
	FestivalID SERIAL PRIMARY KEY, 
	Name VARCHAR(50) NOT NULL CHECK (Name ~ '^[A-Za-z0-9ČĆĐŠŽčćđšž ]+$'), 
	Town VARCHAR(25) NOT NULL CHECK (Town ~ '^[A-Za-z0-9ČĆĐŠŽčćđšž ]+$'), 
	Capacity INT CHECK(Capacity BETWEEN 1000 AND 1000000), 
	StartDate TIMESTAMP CHECK(EXTRACT(YEAR FROM StartDate ) BETWEEN 1900 AND 2050), 
	EndDate TIMESTAMP CHECK(EndDate>StartDate), 
	Status FestivalStatus NOT NULL 
	); 
	
CREATE TABLE Stages (
	StageID SERIAL PRIMARY KEY, 
	Name VARCHAR(30) NOT NULL CHECK (Name ~ '^[A-Za-z0-9ČĆĐŠŽčćđšž ]+$'), 
	Location StageLocation NOT NULL, 
	VisitorCapacity INT CHECK(VisitorCapacity BETWEEN 10 AND 500000 ), 
	HasCover BOOLEAN default FALSE 
); 

CREATE TABLE Performers ( 
	PerformerID SERIAL PRIMARY KEY, 
	Name VARCHAR(30) NOT NULL CHECK (Name ~ '^[A-Za-z0-9ČĆĐŠŽčćđšž ]+$'), 
	Country VARCHAR(30) NOT NULL CHECK (Country ~ '^[A-Za-z0-9ČĆĐŠŽčćđšž ]+$'), 
	Genre VARCHAR(30) NOT NULL , 
	NumberOfMembers INT CHECK(NumberOfMembers BETWEEN 1 AND 150), 
	IsActive BOOLEAN default TRUE 
); 

CREATE TABLE Performances ( 
	PerformanceID SERIAL PRIMARY KEY, 
	StartTime TIME NOT NULL, 
	EndTime TIME NOT NULL, 
	VisitorsNumber INT CHECK(VisitorsNumber BETWEEN 1 AND 500000 ) 
); 

CREATE TABLE Visitors ( 
	VisitorID SERIAL PRIMARY KEY, 
	Name VARCHAR(30) NOT NULL CHECK (Name ~ '^[A-Za-z0-9ČĆĐŠŽčćđšž ]+$'), 
	LastName VARCHAR(30) NOT NULL CHECK (LastName ~ '^[A-Za-z0-9ČĆĐŠŽčćđšž ]+$'), 
	Birthday DATE CHECK(EXTRACT(YEAR FROM Birthday ) BETWEEN 1930 AND 2025), 
	City VARCHAR(50) NOT NULL CHECK (City ~ '^[A-Za-z0-9ČĆĐŠŽčćđšž ]+$'), 
	Email VARCHAR(100) NOT NULL UNIQUE CHECK (Email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'), 
	Country VARCHAR(30) NOT NULL CHECK (Country ~ '^[A-Za-z0-9ČĆĐŠŽčćđšž ]+$') 
); 

CREATE TABLE Tickets ( 
	TicketID SERIAL PRIMARY KEY, 
	Type TicketType NOT NULL, 
	Price FLOAT NOT NULL CHECK(Price BETWEEN 0 AND 500000), 
	Description VARCHAR(100)NOT NULL CHECK (Description ~ '^[A-Za-z0-9ČĆĐŠŽčćđšž ]+$'), 
	Validity TicketValidity NOT NULL 
);

CREATE TABLE Workshop(
	WorkshopID SERIAL PRIMARY KEY, 
	Name VARCHAR(30) NOT NULL CHECK (Name ~ '^[A-Za-z0-9ČĆĐŠŽčćđšž ]+$'), 
	Difficulty WorkshopDifficulty NOT NULL,
	Capacity INT NOT NULL CHECK(Capacity BETWEEN 0 AND 500000),
	DurationHours DECIMAL(4,1) CHECK (DurationHours BETWEEN 0.5 AND 24),
	PriorKnowledge BOOLEAN default FALSE
);

