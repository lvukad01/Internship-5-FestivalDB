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
	
