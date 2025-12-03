-- Database: FestivalDB

-- CREATE TABLES
CREATE TYPE FestivalStatus AS ENUM ('planiran', 'aktivan', 'zavrsen');
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

CREATE TABLE Festivals
{
	FestivalID SERIAL PRIMARY KEY,
	Name VARCHAR(50) NOT NULL CHECK (Name ~ '^[A-Za-z0-9ČĆĐŠŽčćđšž]+$'),
	Town VARCHAR(25) NOT NULL CHECK (Town ~ '^[A-Za-z0-9ČĆĐŠŽčćđšž]+$'),
	Capacity INT CHECK(Capacity BETWEEN 1000 AND 1000000),
	StartDate TIMESTAMP CHECK(EXTRACT(YEAR FROM StartDate ) BETWEEN 1900 AND 2050),
	EndDate TIMESTAMP CHECK(EndDate>StartDate),
	Status FestivalStatus NOT NULL
};

CREATE TABLE Stages
{
	StageID SERIAL PRIMARY KEY,
	Name VARCHAR(30) NOT NULL CHECK (Name ~ '^[A-Za-z0-9ČĆĐŠŽčćđšž]+$'),
	Location StageLocation NOT NULL,
	VisitorCapacity INT CHECK(VisitorCapacity BETWEEN 10 AND 500000 ),
	HasCover BOOL default False
};
CREATE TABLE Performers
{
	PerformerID SERIAL PRIMARY KEY,
	Name VARCHAR(30) NOT NULL CHECK (Name ~ '^[A-Za-z0-9ČĆĐŠŽčćđšž]+$'),
	Country VARCHAR(30) NOT NULL CHECK (Country ~ '^[A-Za-z0-9ČĆĐŠŽčćđšž]+$'),
	Genre VARCHAR(30) NOT NULL CHECK (Genre ~ '^[A-Za-zČĆĐŠŽčćđšž]+$'),
	NumberOfMembers INT CHECK(NumberOfMembers  BETWEEN 1 AND 150),
	IsActive BOOL default True
	};
CREATE TABLE Performances
{
	PerformanceID SERIAL PRIMARY KEY,
	StartTime TIME NOT NULL,
	EndTime TIME NOT NULL,
	VisitorsNumber INT CHECK(VisitorsNumber BETWEEN 1 AND 500000 )
};