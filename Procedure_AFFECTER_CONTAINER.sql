-- -----------------------------------------------------------------------------
--                Procédure : AFFECTER_CONTAINER
-- -----------------------------------------------------------------------------	

-- Concernant le jeu de test : les containers ayant l'identifiant 35 à 43 a été utilisé pour les tests

create or replace PROCEDURE AFFECTER_CONTAINER (
  p_idCont IN NUMBER
) AS
    v_idTrain    	NUMBER; -- Variable pour stocker l'identifiant du train
    v_idWagon    	NUMBER; -- Variable pour stocker l'identifiant du wagon
    v_poidsCont  	NUMBER; -- Variable pour stocker le poids du container
    v_lgCont     	NUMBER; -- Variable pour stocker la longueur du container
    v_idVilleDest	NUMBER; -- Variable pour stocker l'identifiant de la ville de destination
    v_maxKgWagon 	NUMBER; -- Variable pour stocker le poids maximum des wagons
    v_maxLgWagon 	NUMBER; -- Variable pour stocker la longueur maximum des wagons

    -- Curseur pour récupérer les trains desservant la ville de destination
    CURSOR c_trains IS
        SELECT t.idTrain
        FROM Train t, ItineraireTrain it, Arreter a, Ville v
        WHERE t.etatTrain = 'en constitution'
        AND a.idVille = v.idVille
        AND a.idItiTrain = it.idItiTrain
        AND it.idItiTrain = t.idItiTrain
        AND v.idVille = v_idVilleDest
        ORDER BY t.dateTrain ASC;

BEGIN
-- Récupérer les détails du container
    SELECT poidsCont, lgCont, idVilleDestiner
    INTO v_poidsCont, v_lgCont, v_idVilleDest
    FROM Container
    WHERE idCont = p_idCont;

-- Vérifier la compatibilité du container avec les wagons dispo

    -- Récupérer les valeurs max concernant la taille et le poids des wagons
    SELECT MAX(maxKgWagon), MAX(lgWagon)
    INTO v_maxKgWagon, v_maxLgWagon
    FROM Wagon
    WHERE etatWagon = 'OK';

    -- Vérifier si le container est compatible avec les wagons et mettre à jour l'état du container si compatible
    IF v_poidsCont > v_maxKgWagon OR v_lgCont > v_maxLgWagon THEN
        UPDATE Container
        SET etatCont = 'Format incompatible', idtrainaffecter = null, idwagonaffecter = null
        WHERE idCont = p_idCont;
        RETURN;
    END IF;

-- Trouver un train disponible pour la ville
    OPEN c_trains;
    FETCH c_trains INTO v_idTrain;

-- Vérifier si aucun train ne dessert la ville et mettre à jour l'état du container si aucun train n'est trouvé
    IF c_trains%NOTFOUND THEN
        CLOSE c_trains;
        UPDATE Container
        SET etatCont = 'Affecter transports routier'
        WHERE idCont = p_idCont;
        RETURN;
    ELSE

-- Trouver le wagon compatible avec le container grace à la fonction TROUVER_WAGON
        v_idWagon := TROUVER_WAGON(v_poidsCont, v_lgCont, v_idVilleDest, v_idTrain);

        -- Mise à jour de l'état du container lorsque le wagon compatible est trouvé
        IF v_idWagon IS NOT NULL THEN
            UPDATE Container
            SET idtrainaffecter = v_idTrain,
                idwagonaffecter = v_idWagon,
                etatCont = 'Chargé'
            WHERE idCont = p_idCont;
        
        ELSE
        -- Mise à jour lorsque le wagon compatible n'est pas trouvé (attente de wagon)
            UPDATE Container
            SET idtrainaffecter = v_idTrain,
                idwagonaffecter = NULL,
                etatCont = 'Attente de wagon'
            WHERE idCont = p_idCont;
        END IF;
    END IF;

    CLOSE c_trains;  -- Fermeture du curseur au cas où la condition %NOTFOUND n'est pas remplie

END AFFECTER_CONTAINER;
