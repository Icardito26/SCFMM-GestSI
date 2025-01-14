-- -----------------------------------------------------------------------------
--                Fonction : TROUVER_WAGON
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION TROUVER_WAGON(
    p_poidsCont     NUMBER,
    p_lgCont        NUMBER,
    p_idVilleDest   NUMBER,
    p_idTrain       NUMBER
) RETURN WAGON.IDWAGON%TYPE
AS
  -- Déclaration du curseur pour les wagons disponibles et compatibles avec le container à affecter
  CURSOR c_wagons IS
    SELECT w.idWagon
    FROM Wagon w
    WHERE w.etatWagon = 'OK'
      AND w.maxKgWagon >= p_poidsCont
      AND w.lgWagon >= p_lgCont
      AND NOT EXISTS (
        SELECT 1
        FROM ConstituerW cw
        WHERE cw.idWagon = w.idWagon
          AND cw.idTrain = p_idTrain
      )
    ORDER BY w.maxKgWagon ASC, w.lgWagon ASC;

  v_idWagon         WAGON.IDWAGON%TYPE; -- variable pour stocker l'ID du wagon trouvé
  v_count           NUMBER := 0; -- variable pour stocker le nombre de wagons compatibles
  v_result          WAGON.IDWAGON%TYPE; -- variable pour stocker l'ID du wagon trouvé
  v_totalLgCont     NUMBER := 0; -- variable pour stocker la longueur totale des containers
  v_count2          NUMBER := 0; -- variable pour stocker le nombre de wagons compatibles
  v_maxkgwagon      NUMBER := 0; -- variable pour stocker le poids maximum des wagons
  v_poidstotal      NUMBER := 0; -- variable pour stocker le poids total des containers

BEGIN

  -- Ouverture du curseur
  OPEN c_wagons;
  FETCH c_wagons INTO v_idWagon;

      -- Si aucun wagon n'est trouvé, fermer le curseur et retourner NULL
      IF c_wagons%NOTFOUND THEN
        CLOSE c_wagons;
        RETURN NULL;
      END IF;

      -- Mise à jour de l'état du wagon trouvé à 'KO'
      UPDATE Wagon
      SET etatWagon = 'KO'
      WHERE idWagon = v_idWagon;

      COMMIT;

  -- Vérification et insertion dans ConstituerW
  BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM ConstituerW
    WHERE idWagon = v_idWagon
    AND idTrain = p_idTrain;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_count := 0;
  END;

      -- Si le wagon n'est pas associé au train, l'ajouter
      IF v_count = 0 THEN
        INSERT INTO ConstituerW (idWagon, idTrain)
        VALUES (v_idWagon, p_idTrain);
      END IF;

  -- Vérifier s'il reste de la place dans le wagon
  BEGIN
    SELECT COUNT(W.IDWAGON), W.maxkgwagon, SUM(C.POIDSCONT)
    INTO v_count2, v_maxkgwagon, v_poidstotal
    FROM "CONTAINER" C, TRAIN T, CONSTITUERW CW, WAGON W
    WHERE C.IDTRAINAFFECTER = T.IDTRAIN 
      AND C.IDWAGONAFFECTER = W.IDWAGON 
      AND T.IDTRAIN = CW.IDTRAIN 
      AND CW.IDWAGON = W.IDWAGON
    GROUP BY T.IDTRAIN, W.IDWAGON, W.maxkgwagon
    HAVING T.IDTRAIN = p_idTrain AND SUM(C.POIDSCONT) + p_poidsCont <= W.maxkgwagon;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_count2 := 0;
      v_maxkgwagon := 0;
      v_poidstotal := 0;
  END;

  -- Si le poids total des containers est inférieur ou égal au poids maximum du wagon affecter le container au wagon
  IF v_count2 != 0 THEN
    UPDATE Container
    SET idTrainAffecter = p_idTrain,
        idWagonAffecter = v_idWagon,
        etatCont = 'affecté'
    WHERE idCont = (SELECT idCont
                    FROM Container
                    WHERE idTrainAffecter IS NULL
                      AND idWagonAffecter IS NULL
                      AND ROWNUM = 1);
  END IF;

  COMMIT;

  -- Fermer le curseur
  CLOSE c_wagons;

  -- Retourner l'ID du wagon trouvé
  RETURN v_idWagon;

END TROUVER_WAGON;


TEETETE