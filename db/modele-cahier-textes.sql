SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL';

CREATE SCHEMA IF NOT EXISTS `cahiertextes` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci ;
USE `cahiertextes` ;

-- -----------------------------------------------------
-- Table `cahiertextes`.`cahier_textes`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahiertextes`.`cahier_textes` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT 'identifiant unique du cahier de textes' ,
  `regrpnt_id` INT NOT NULL COMMENT 'identifiant unique du regroupement auquel le cahier de textes est attaché' ,
  `lib` VARCHAR(45) NULL COMMENT 'Libellé affiché du cahier de textes : ex cahier de textes de la 6eme2.' ,
  `deb_annee_scolaire` DECIMAL(10,0) NOT NULL COMMENT 'millésime de début de l\'année scolaire' ,
  `fin_annee_scolaire` DECIMAL(10,0) NOT NULL COMMENT 'millésime de la fin de l\'année scolaire' ,
  `date_creation` DATETIME NULL ,
  `deleted` TINYINT(1) NULL DEFAULT false ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `cahiertextes`.`Ressource`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahiertextes`.`Ressource` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `lib` VARCHAR(80) NOT NULL ,
  `doc_id` INT NULL COMMENT 'id de la ressource émanant du service de gestion documentaire.' ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB
COMMENT = 'Table des ressources liées aux cahiers de textes, pour les c' /* comment truncated */;


-- -----------------------------------------------------
-- Table `cahiertextes`.`plage_horaire`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahiertextes`.`plage_horaire` (
  `id` VARCHAR(10) NOT NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB
COMMENT = 'Toutes les plage horaire de M1 à M5, et de S1 à S5';


-- -----------------------------------------------------
-- Table `cahiertextes`.`cours`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahiertextes`.`cours` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `usr_id` VARCHAR(16) NOT NULL COMMENT 'id de l\'utilisateur qui a saisi ce cours.' ,
  `mat_id` VARCHAR(16) NOT NULL COMMENT 'code matière de l\'éducation nationale' ,
  `cahier_textes_id` INT NOT NULL ,
  `Ressource_id` INT NOT NULL ,
  `plage_horaire_id` VARCHAR(10) NOT NULL ,
  `contenu` TEXT NOT NULL ,
  `date_cours` DATETIME NULL COMMENT 'date à laquelle a eu lieu le cours' ,
  `date_creation` DATETIME NULL COMMENT 'date de création bdd de cet enregistrement' ,
  `date_modif` DATETIME NULL COMMENT 'date de modification bdd de cet enregistrement' ,
  `date_valid` DATETIME NULL COMMENT 'date de validation de cette saisie par le principal' ,
  `deleted` TINYINT(1) NOT NULL DEFAULT false COMMENT 'Flag de suppression, si true a lors l\'enregistrement est considéré comme supprimé. Cela permet d\'implémenter une suppression logique plutôt que physique.' ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_cours_cahier_textes1` (`cahier_textes_id` ASC) ,
  INDEX `crs_mat_id_idx` USING BTREE (`mat_id` ASC) ,
  INDEX `crs_usr_id_idx` (`usr_id` ASC) ,
  INDEX `fk_cours_Ressource1` (`Ressource_id` ASC) ,
  INDEX `fk_cours_plage_horaire1` (`plage_horaire_id` ASC) ,
  CONSTRAINT `fk_cours_cahier_textes1`
    FOREIGN KEY (`cahier_textes_id` )
    REFERENCES `cahiertextes`.`cahier_textes` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_cours_Ressource1`
    FOREIGN KEY (`Ressource_id` )
    REFERENCES `cahiertextes`.`Ressource` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_cours_plage_horaire1`
    FOREIGN KEY (`plage_horaire_id` )
    REFERENCES `cahiertextes`.`plage_horaire` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `cahiertextes`.`type_devoir`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahiertextes`.`type_devoir` (
  `id` INT NOT NULL ,
  `lib` VARCHAR(80) NULL ,
  `description` TEXT NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB
COMMENT = 'Tpe de devoir : DS, DM, Exposé, ....';


-- -----------------------------------------------------
-- Table `cahiertextes`.`devoir`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahiertextes`.`devoir` (
  `id` INT NOT NULL AUTO_INCREMENT COMMENT 'clé primaire' ,
  `Type_devoir_id` INT NOT NULL ,
  `cours_id` INT NOT NULL ,
  `Ressource_id` INT NOT NULL ,
  `contenu` TEXT NULL COMMENT 'contenu des devoirs' ,
  `temps_estime` INT NULL COMMENT 'temps de travail estimé en minutes' ,
  `date_devoir` DATETIME NULL COMMENT 'date de rendu du devoir' ,
  `date_creation` DATETIME NULL COMMENT 'date de création bdd de cet enregistrement' ,
  `date_modif` DATETIME NULL ,
  `date_valid` DATETIME NULL COMMENT 'date de validation de cette entrée.' ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_Devoirs_Type_devoir` (`Type_devoir_id` ASC) ,
  INDEX `fk_devoir_cours1` (`cours_id` ASC) ,
  INDEX `fk_devoir_Ressource1` (`Ressource_id` ASC) ,
  CONSTRAINT `fk_Devoirs_Type_devoir`
    FOREIGN KEY (`Type_devoir_id` )
    REFERENCES `cahiertextes`.`type_devoir` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_devoir_cours1`
    FOREIGN KEY (`cours_id` )
    REFERENCES `cahiertextes`.`cours` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_devoir_Ressource1`
    FOREIGN KEY (`Ressource_id` )
    REFERENCES `cahiertextes`.`Ressource` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
COMMENT = 'Tables des devoirs. \nUn devoir est focément léi à un cours.';


-- -----------------------------------------------------
-- Table `cahiertextes`.`log_visu`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahiertextes`.`log_visu` (
  `usr_id` INT NOT NULL ,
  `Ressource_id` INT NOT NULL ,
  PRIMARY KEY (`usr_id`, `Ressource_id`) ,
  INDEX `fk_log_visu_Ressource1` (`Ressource_id` ASC) ,
  CONSTRAINT `fk_log_visu_Ressource1`
    FOREIGN KEY (`Ressource_id` )
    REFERENCES `cahiertextes`.`Ressource` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
COMMENT = 'Logs de visualisation d\'une ressource par les élèves.';


-- -----------------------------------------------------
-- Table `cahiertextes`.`fait`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahiertextes`.`fait` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `usr_id` VARCHAR(16) NULL ,
  `devoir_id` INT NOT NULL ,
  `date_fait` DATETIME NULL COMMENT 'date à laquelle le devoir a été coché comme fait (équivaut à la date de création en bdd)' ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_todo_done_devoir1` (`devoir_id` ASC) ,
  CONSTRAINT `fk_todo_done_devoir1`
    FOREIGN KEY (`devoir_id` )
    REFERENCES `cahiertextes`.`devoir` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
COMMENT = 'Table des devoirs faits par élève.\ntout ce qui est à faire n' /* comment truncated */;



SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

-- -----------------------------------------------------
-- Data for table `cahiertextes`.`plage_horaire`
-- -----------------------------------------------------
START TRANSACTION;
USE `cahiertextes`;
INSERT INTO `cahiertextes`.`plage_horaire` (`id`) VALUES ('M1');
INSERT INTO `cahiertextes`.`plage_horaire` (`id`) VALUES ('M2');
INSERT INTO `cahiertextes`.`plage_horaire` (`id`) VALUES ('M3');
INSERT INTO `cahiertextes`.`plage_horaire` (`id`) VALUES ('M4');
INSERT INTO `cahiertextes`.`plage_horaire` (`id`) VALUES ('M5');
INSERT INTO `cahiertextes`.`plage_horaire` (`id`) VALUES ('S1');
INSERT INTO `cahiertextes`.`plage_horaire` (`id`) VALUES ('S2');
INSERT INTO `cahiertextes`.`plage_horaire` (`id`) VALUES ('S3');
INSERT INTO `cahiertextes`.`plage_horaire` (`id`) VALUES ('S4');
INSERT INTO `cahiertextes`.`plage_horaire` (`id`) VALUES ('S5');

COMMIT;

-- -----------------------------------------------------
-- Data for table `cahiertextes`.`type_devoir`
-- -----------------------------------------------------
START TRANSACTION;
USE `cahiertextes`;
INSERT INTO `cahiertextes`.`type_devoir` (`id`, `lib`, `description`) VALUES (1, 'DS', 'Devoir surveillé');
INSERT INTO `cahiertextes`.`type_devoir` (`id`, `lib`, `description`) VALUES (2, 'DM', 'Devoir à la maison');
INSERT INTO `cahiertextes`.`type_devoir` (`id`, `lib`, `description`) VALUES (3, 'Leçon', 'Leçon à apprendre');
INSERT INTO `cahiertextes`.`type_devoir` (`id`, `lib`, `description`) VALUES (4, 'Exposé', 'Exposé à préparer');
INSERT INTO `cahiertextes`.`type_devoir` (`id`, `lib`, `description`) VALUES (5, 'Recherche', 'Recherche à faire');
INSERT INTO `cahiertextes`.`type_devoir` (`id`, `lib`, `description`) VALUES (6, 'Exercice', 'Exercice à faire');

COMMIT;
