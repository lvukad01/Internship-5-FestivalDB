CREATE OR REPLACE FUNCTION check_performance_overlap()
RETURNS TRIGGER AS $$
BEGIN

    IF EXISTS (
        SELECT 1  
        FROM Performances p
        WHERE (
            p.StageID = NEW.StageID
            AND (NEW.StartTime < p.EndTime)
            AND (NEW.EndTime > p.StartTime)
            )
    ) THEN
        RAISE EXCEPTION 'Nastup (%) kojem je početak u (%) se preklapa s drugim nastupom na pozornici pod ID-em (%).',
		NEW.PerformanceID, NEW.StartTime, NEW.StageID;
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

	IF NEW.VisitorsNumber > stageCapacity THEN
		RAISE EXCEPTION 'Broj posjetitelja (%) za pozornicu s ID-em (%), premašuje kapacitet pozornice (%)', 
			NEW.VisitorsNumber,NEW.StageID, stageCapacity;
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
		RAISE EXCEPTION 'Ukupan broj karata (% + %) za festival ID-a (%) prelazi kapacitet festivala (%)',
			soldTickets, NEW.Quantity, FestivalID, festivalCapacity;
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
	END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_membership_card
BEFORE INSERT ON MembershipCard
FOR EACH ROW
EXECUTE FUNCTION check_membership_card();




CREATE OR REPLACE FUNCTION assign_membership_card()
RETURNS TRIGGER AS $$
DECLARE
    festival_count INT;
    total_spent FLOAT;
BEGIN
    SELECT 
        COUNT(DISTINCT p.festivalid),
        COALESCE(SUM(p.totalprice), 0)
    INTO festival_count, total_spent
    FROM Purchases p
    WHERE p.visitorid = NEW.visitorid;

    IF NOT EXISTS (SELECT 1 FROM MembershipCard mc WHERE mc.visitorid = NEW.visitorid) THEN
        IF festival_count > 3 AND total_spent > 600 THEN
            INSERT INTO MembershipCard(visitorid, activationdate, status)
            VALUES (NEW.visitorid, NOW(), 'aktivan');
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;




CREATE TRIGGER trg_assign_membership_card
AFTER INSERT ON Purchases
FOR EACH ROW
EXECUTE FUNCTION assign_membership_card();
	






CREATE OR REPLACE FUNCTION check_staff_festival_overlap()
RETURNS TRIGGER AS $$
DECLARE 
    existingStart TIMESTAMP;
    existingEnd TIMESTAMP;
    newStart TIMESTAMP;
    newEnd TIMESTAMP;
BEGIN
    SELECT f.StartDate, f.EndDate
    INTO existingStart, existingEnd
    FROM Festivals f
    JOIN Staff s ON s.FestivalID = f.FestivalID
    WHERE s.StaffID = NEW.StaffID;

    IF FOUND AND NEW.FestivalID IS NOT NULL THEN
        
        SELECT StartDate, EndDate
        INTO newStart, newEnd
        FROM Festivals
        WHERE FestivalID = NEW.FestivalID;

        IF (newStart <= existingEnd AND newEnd >= existingStart) THEN
            RAISE EXCEPTION 'Osoba već radi na festivalu u istom periodu.';
        END IF;

    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_check_staff_festival_overlap
BEFORE INSERT OR UPDATE ON Staff
FOR EACH ROW
EXECUTE FUNCTION check_staff_festival_overlap();

CREATE OR REPLACE FUNCTION update_festival_status()
RETURNS TRIGGER AS $$
BEGIN
    IF CURRENT_DATE < NEW.StartDate::date THEN
        NEW.Status := 'planiran';
    ELSIF CURRENT_DATE >= NEW.StartDate::date AND CURRENT_DATE <= NEW.EndDate::date THEN
        NEW.Status := 'aktivan';
    ELSE
        NEW.Status := 'zavrsen';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_festival_status ON Festivals;
CREATE TRIGGER trg_update_festival_status
BEFORE INSERT OR UPDATE ON Festivals
FOR EACH ROW
EXECUTE FUNCTION update_festival_status();

CREATE OR REPLACE FUNCTION set_ticket_description()
RETURNS TRIGGER AS $$
BEGIN
    CASE NEW.Type::text
        WHEN 'jednodnevna' THEN NEW.Description := 'Ulaznica za jedan dan festivala';
        WHEN 'festivalska' THEN NEW.Description := 'Ulaznica za cijeli festival';
        WHEN 'VIP' THEN NEW.Description := 'VIP ulaznica s posebnim pogodnostima';
        WHEN 'kamp' THEN NEW.Description := 'Ulaznica uključuje kampiranje';
        WHEN 'early_bird' THEN NEW.Description := 'Rani popust za ulaznicu';
        WHEN 'student' THEN NEW.Description := 'Ulaznica s popustom za studente';
        WHEN 'family' THEN NEW.Description := 'Obiteljska ulaznica';
        WHEN 'premium' THEN NEW.Description := 'Premium ulaznica s dodatnim pogodnostima';
        ELSE NEW.Description := 'Nepoznati tip karte';
    END CASE;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ticket_description_trigger
BEFORE INSERT ON Tickets
FOR EACH ROW
EXECUTE FUNCTION set_ticket_description();
