CREATE OR REPLACE FUNCTION check_performance_overlap()
RETURNS TRIGGER AS $$
BEGIN

    IF EXISTS (
        SELECT 1  
        FROM Performances p
        WHERE 
            p.StageID = NEW.StageID
            AND (NEW.StartTime < p.EndTime)
            AND (NEW.EndTime > p.StartTime)
            )
    ) THEN
        RAISE EXCEPTION 'Nastup se preklapa s drugim nastupom na istoj pozornici.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_performance_overlap
BEFORE INSERT OR UPDATE ON Performances
FOR EACH ROW
EXECUTE FUNCTION check_performance_overlap();





CREATE OR REPLACE FUNCTION check_performance_visitors()
RETURNS TRIGGER AS $$
DECLARE stageCapacity INT;
BEGIN

	SELECT VisitorCapacity INTO stageCapacity
	FROM Stages
	WHERE StageID=NEW.StageID;

	IF NEW.VisitorsNumber > stageCapacity
		RAISE EXCEPTION 'Broj posjetitelja (%), premašuje kapacitet pozornice (%)', 
			NEW.VisitorsNumber, stageCapacity;
	END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_performance_visitors
BEFORE INSERT OR UPDATE ON Performances
FOR EACH ROW
EXECUTE FUNCTION check_performance_visitors();




CREATE OR REPLACE FUNCTION check_festival_capacity()
RETURNS TRIGGER AS $$
DECLARE festivalCapacity INT;
DECLARE soldTickets INT;
BEGIN

	SELECT Capacity INTO festivalCapacity 
	FROM Festivals
	WHERE FestivalID=(SELECT FestivalID FROM Purchases WHERE PurchaseID = NEW.PurchaseID);
	
	SELECT COALESCE(SUM(pi.Quantity)) INTO soldTickets
	FROM PurchaseItems pi
	JOIN Purchases p ON pi.PurchaseID = p.PurchaseID
	WHERE p.FestivalID = (SELECT FestivalID FROM Purchases WHERE PurchaseID = NEW.PurchaseID);
	
	IF soldTickets+NEW.Quantity>festivalCapacity THEN
		RAISE EXCEPTION 'Ukupan broj karata (% + %) prelazi kapacitet festivala (%)',
			soldTickets, NEW.Quantity, festivalCapacity;
	END IF;
	
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_festival_capacity
BEFORE INSERT OR UPDATE ON PurchaseItems
FOR EACH ROW
EXECUTE FUNCTION check_festival_capacity();





CREATE OR REPLACE FUNCTION update_total_price()
RETURNS TRIGGER AS $$
DECLARE total FLOAT;
BEGIN
	SELECT SUM(pi.Quantity*t.Price) INTO total
	FROM PurchaseItems pi
	JOIN tickets t ON pi.TicketID=t.TicketID
	WHERE pi.PurchaseID=NEW.PurchaseID;

	UPDATE Purchases
	SET totalPrice=COALESCE(total,0)
	WHERE PurchaseID=NEW.PurchaseID;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_total_price
BEFORE INSERT OR UPDATE OR DELETE ON PurchaseItems
FOR EACH ROW
EXECUTE FUNCTION update_total_price();




CREATE OR REPLACE FUNCTION check_membership_card()
RETURNS TRIGGER AS $$
BEGIN

	IF EXISTS (
		SELECT 1
		FROM MembershipCard
		WHERE VisitorID = NEW.VisitorID
    ) THEN
        RAISE EXCEPTION 'Posjetitelj već ima Membership Card.';
    END IF;
	IF NEW.ActivationDate > NOW() THEN
        RAISE EXCEPTION 'Datum aktivacije ne može biti u budućnosti.';
	END IF
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_membership_card
BEFORE INSERT ON MembershipCard
FOR EACH ROW
EXECUTE FUNCTION check_membership_card();




CREATE OR UPDATE assign_membership_card()
RETURNS TRIGGER AS $$
DECLARE festivalCount INT;
DECLARE totalSpent FLOAT;
BEGIN
	SELECT COUNT(DISTINCT FestivalID ) INTO festivalCount
	FROM Purchases
	WHERE VisitorID=NEW.VisitorID;
	
	SELECT COALESCE(SUM(TotalPrice),0) INTO totalSpent
    FROM Purchases
    WHERE VisitorID = NEW.VisitorID;
    IF festival_count > 3 AND total_spent > 600 THEN
        IF NOT EXISTS (
            SELECT 1 FROM MembershipCard
            WHERE VisitorID = NEW.VisitorID
        ) THEN
            INSERT INTO MembershipCard(ActivationDate, Status, VisitorID)
            VALUES (NOW(), 'aktivan', NEW.VisitorID);
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_assign_membership_card
AFTER INSERT ON Purchases
FOR EACH ROW
EXECUTE FUNCTION assign_membership_card();
	



CREATE OR REPLACE FUNCTION check_workshop_registration()
RETURNS TRIGGER AS $$
DECLARE currentParticipants INT;
DECLARE requiredKnowledge BOOLEAN;
BEGIN
    SELECT COUNT(*) INTO currentParticipants
    FROM VisitorWorkshops
    WHERE WorkshopID = NEW.WorkshopID;

    SELECT PriorKnowledge INTO requiredKnowledge
    FROM Workshops
    WHERE WorkshopID = NEW.WorkshopID;

    IF currentParticipants >= (SELECT Capacity FROM Workshops WHERE WorkshopID = NEW.WorkshopID) THEN
        RAISE EXCEPTION 'Radionica je popunjena. Maksimalni broj polaznika je %', 
            (SELECT Capacity FROM Workshops WHERE WorkshopID = NEW.WorkshopID);
    END IF;

    IF requiredKnowledge AND NEW.Status = 'prijavljen' THEN
        IF NOT NEW.HasPriorKnowledge THEN
            RAISE EXCEPTION 'Radionica zahtijeva prethodno znanje.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_workshop_registration
BEFORE INSERT OR UPDATE ON VisitorWorkshops
FOR EACH ROW
EXECUTE FUNCTION check_workshop_registration();



CREATE OR REPLACE FUNCTION check_staff_festival_overlap()
RETURNS TRIGGER AS $$
DECLARE existingStart TIMESTAMP;
DECLARE existingEnd TIMESTAMP;
BEGIN
    SELECT f.StartDate, f.EndDate INTO existingStart, existingEnd
    FROM Festivals f
    JOIN Staff s ON s.FestivalID = f.FestivalID
    WHERE s.StaffID = NEW.StaffID;

    IF FOUND THEN
        IF (NEW.FestivalID IS NOT NULL) THEN
            DECLARE newStart TIMESTAMP;
            DECLARE newEnd TIMESTAMP;
            SELECT StartDate, EndDate
            INTO newStart, newEnd
            FROM Festivals
            WHERE FestivalID = NEW.FestivalID;

            IF (newStart <= existingEnd AND newEnd >= existingStart) THEN
                RAISE EXCEPTION 'Osoba već radi na festivalu u istom periodu.';
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_staff_festival_overlap
BEFORE INSERT OR UPDATE ON Staff
FOR EACH ROW
EXECUTE FUNCTION check_staff_festival_overlap();
