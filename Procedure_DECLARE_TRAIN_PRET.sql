-- -----------------------------------------------------------------------------
--       Procédure : DECLARE_TRAIN_PRET
-- -----------------------------------------------------------------------------

-- Concernant le jeu de test : le train ayant l'identifiant 405 a été utilisé pour les tests

create or replace PROCEDURE DECLARE_TRAIN_PRET (
    v_idTrain IN INT
)
AS
  v_wagons_ok_count   NUMBER; -- Variable pour stocker le nombre de wagons en état 'OK'
BEGIN

  -- Vérifier si tous les wagons associés au train ont un état différent de 'OK'
    SELECT COUNT(w.idWagon)
    INTO v_wagons_ok_count
    FROM Train t, ConstituerW cw, wagon w
    WHERE w.idWagon = cw.idWagon
    AND cw.idTrain = t.idTrain
    AND t.idTrain = v_idTrain
    AND w.etatWagon = 'OK';
 
  -- Si aucun wagon n'est en état 'OK', mettre à jour l'état du train
    IF v_wagons_ok_count = 0 THEN
      UPDATE Train
      SET etatTrain = 'Pret à partir'
      WHERE idTrain = v_idTrain;

    -- Valider la mise à jour
      COMMIT;
    END IF;
END;

/*
Pour cette procédure, il est attendu que le train soit prêt à partir si tous les wagons associés 
à ce train ont un état différent de 'OK'.
*/
