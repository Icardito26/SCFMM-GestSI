-- -----------------------------------------------------------------------------
--       Procédure : ETAT_TRAIN_PARTI
-- -----------------------------------------------------------------------------

-- Concernant le jeu de test : le train ayant l'identifiant 405 a été utilisé pour les tests

create or replace PROCEDURE ETAT_TRAIN_PARTI (
    v_idTrain IN INT
)
AS
    v_dateAuj	    DATE; -- Variable pour stocker la date actuelle
    v_datedepart  DATE; -- Variable pour stocker la date de départ du train
    v_etatTrain   VARCHAR2(100); -- Variable pour stocker l'état actuel du train
 
BEGIN
-- Récupérer la date actuelle
    SELECT SYSDATE
    INTO v_dateAuj
    FROM DUAL;

-- Récupérer la date de départ du train
    SELECT dateTrain
    INTO v_datedepart
    FROM Train
    WHERE idTrain = v_idTrain;
 
-- Récupérer l'état actuel du train
    SELECT etatTrain
    INTO v_etatTrain
    FROM Train
    WHERE idTrain = v_idTrain;

  -- Comparer les dates et modifier l'état du train si nécessaire
    IF TRUNC(v_dateAuj) >= TRUNC(v_datedepart) AND v_etatTrain = 'Pret à partir' THEN
    UPDATE Train
    SET etatTrain = 'Parti'
    WHERE idTrain = v_idTrain;
    ELSE
    DBMS_OUTPUT.PUT_LINE('Le train n''est pas encore parti ou n''est pas prêt à partir.');
    END IF;
END;

UPDATE Container
SET idTrainAffecter = NULL, idWagonAffecter = NULL, etatCont = 'En cours d''affection';
COMMIT;

/*
Pour cette procédure, il est attendu que l'état du train soit mis à jour à 'Parti' si la date actuelle 
est supérieure ou égale à la date de départ du train et que l'état du train est 'Pret à partir'.
*/