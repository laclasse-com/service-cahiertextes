SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

CREATE SCHEMA IF NOT EXISTS `cahierdetextes` DEFAULT CHARACTER SET latin1 ;
USE `cahierdetextes` ;

-- -----------------------------------------------------
-- Table `cahierdetextes`.`cahier_de_textes`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahierdetextes`.`cahier_de_textes` (
  `id` INT(11) NOT NULL AUTO_INCREMENT ,
  `regroupement_id` INT(11) NULL DEFAULT NULL ,
  `debut_annee_scolaire` DATE NULL DEFAULT NULL ,
  `fin_annee_scolaire` DATE NULL DEFAULT NULL ,
  `date_creation` DATETIME NULL DEFAULT NULL ,
  `label` VARCHAR(255) NULL DEFAULT NULL ,
  `deleted` TINYINT(1) NULL DEFAULT '0' ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `cahierdetextes`.`plage_horaire`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahierdetextes`.`plage_horaire` (
  `id` INT(11) NOT NULL AUTO_INCREMENT ,
  `label` VARCHAR(255) NULL DEFAULT NULL ,
  `debut` TIME NULL DEFAULT NULL ,
  `fin` TIME NULL DEFAULT NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB
AUTO_INCREMENT = 21
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `cahierdetextes`.`creneau_emploi_du_temps`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahierdetextes`.`creneau_emploi_du_temps` (
  `id` INT(11) NOT NULL AUTO_INCREMENT ,
  `jour_de_la_semaine` INT(11) NULL DEFAULT NULL ,
  `debut` INT(11) NULL DEFAULT NULL ,
  `fin` INT(11) NULL DEFAULT NULL ,
  `matiere_id` INT(11) NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `debut` (`debut` ASC) ,
  INDEX `fin` (`fin` ASC) ,
  CONSTRAINT `creneau_emploi_du_temps_ibfk_1`
    FOREIGN KEY (`debut` )
    REFERENCES `cahierdetextes`.`plage_horaire` (`id` ),
  CONSTRAINT `creneau_emploi_du_temps_ibfk_2`
    FOREIGN KEY (`fin` )
    REFERENCES `cahierdetextes`.`plage_horaire` (`id` ))
ENGINE = InnoDB
AUTO_INCREMENT = 702
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `cahierdetextes`.`cours`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahierdetextes`.`cours` (
  `id` INT(11) NOT NULL AUTO_INCREMENT ,
  `creneau_emploi_du_temps_id` INT(11) NULL DEFAULT NULL ,
  `cahier_de_textes_id` INT(11) NULL DEFAULT NULL ,
  `enseignant_id` INT(11) NULL DEFAULT NULL ,
  `date_cours` DATE NULL DEFAULT NULL ,
  `date_creation` DATETIME NULL DEFAULT NULL ,
  `date_modification` DATETIME NULL DEFAULT NULL ,
  `date_validation` DATETIME NULL DEFAULT NULL ,
  `contenu` VARCHAR(255) NULL DEFAULT NULL ,
  `deleted` TINYINT(1) NULL DEFAULT '0' ,
  PRIMARY KEY (`id`) ,
  INDEX `creneau_emploi_du_temps_id` (`creneau_emploi_du_temps_id` ASC) ,
  INDEX `cahier_de_textes_id` (`cahier_de_textes_id` ASC) ,
  CONSTRAINT `cours_ibfk_1`
    FOREIGN KEY (`creneau_emploi_du_temps_id` )
    REFERENCES `cahierdetextes`.`creneau_emploi_du_temps` (`id` ),
  CONSTRAINT `cours_ibfk_2`
    FOREIGN KEY (`cahier_de_textes_id` )
    REFERENCES `cahierdetextes`.`cahier_de_textes` (`id` ))
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `cahierdetextes`.`ressource`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahierdetextes`.`ressource` (
  `id` INT(11) NOT NULL AUTO_INCREMENT ,
  `label` VARCHAR(255) NULL DEFAULT NULL ,
  `doc_id` INT(11) NULL DEFAULT NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `cahierdetextes`.`cours_ressource`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahierdetextes`.`cours_ressource` (
  `cours_id` INT(11) NOT NULL ,
  `ressource_id` INT(11) NOT NULL ,
  PRIMARY KEY (`cours_id`, `ressource_id`) ,
  INDEX `cours_ressource_ressource_id_cours_id_index` (`ressource_id` ASC, `cours_id` ASC) ,
  CONSTRAINT `cours_ressource_ibfk_1`
    FOREIGN KEY (`cours_id` )
    REFERENCES `cahierdetextes`.`cours` (`id` ),
  CONSTRAINT `cours_ressource_ibfk_2`
    FOREIGN KEY (`ressource_id` )
    REFERENCES `cahierdetextes`.`ressource` (`id` ))
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `cahierdetextes`.`creneau_emploi_du_temps_enseignant`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahierdetextes`.`creneau_emploi_du_temps_enseignant` (
  `creneau_emploi_du_temps_id` INT(11) NOT NULL DEFAULT '0' ,
  `enseignant_id` INT(11) NOT NULL DEFAULT '0' ,
  `semaines_de_presence` BIGINT(20) NULL DEFAULT NULL ,
  PRIMARY KEY (`creneau_emploi_du_temps_id`, `enseignant_id`) ,
  CONSTRAINT `creneau_emploi_du_temps_enseignant_ibfk_1`
    FOREIGN KEY (`creneau_emploi_du_temps_id` )
    REFERENCES `cahierdetextes`.`creneau_emploi_du_temps` (`id` ))
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `cahierdetextes`.`creneau_emploi_du_temps_regroupement`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahierdetextes`.`creneau_emploi_du_temps_regroupement` (
  `creneau_emploi_du_temps_id` INT(11) NOT NULL DEFAULT '0' ,
  `regroupement_id` INT(11) NOT NULL DEFAULT '0' ,
  `semaines_de_presence` BIGINT(20) NULL DEFAULT NULL ,
  PRIMARY KEY (`creneau_emploi_du_temps_id`, `regroupement_id`) ,
  CONSTRAINT `creneau_emploi_du_temps_regroupement_ibfk_1`
    FOREIGN KEY (`creneau_emploi_du_temps_id` )
    REFERENCES `cahierdetextes`.`creneau_emploi_du_temps` (`id` ))
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `cahierdetextes`.`etablissement`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahierdetextes`.`etablissement` (
  `id` INT(11) NOT NULL AUTO_INCREMENT ,
  `UAI` VARCHAR(255) NULL DEFAULT NULL ,
  `debut_annee_scolaire` DATE NULL DEFAULT NULL ,
  `fin_annee_scolaire` DATE NULL DEFAULT NULL ,
  `date_premier_jour_premiere_semaine` DATE NULL DEFAULT NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB
AUTO_INCREMENT = 2
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `cahierdetextes`.`salle`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahierdetextes`.`salle` (
  `id` INT(11) NOT NULL AUTO_INCREMENT ,
  `etablissement_id` INT(11) NULL DEFAULT NULL ,
  `identifiant` VARCHAR(255) NULL DEFAULT NULL ,
  `nom` VARCHAR(255) NULL DEFAULT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `etablissement_id` (`etablissement_id` ASC) ,
  CONSTRAINT `salle_ibfk_1`
    FOREIGN KEY (`etablissement_id` )
    REFERENCES `cahierdetextes`.`etablissement` (`id` ))
ENGINE = InnoDB
AUTO_INCREMENT = 25
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `cahierdetextes`.`creneau_emploi_du_temps_salle`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahierdetextes`.`creneau_emploi_du_temps_salle` (
  `creneau_emploi_du_temps_id` INT(11) NOT NULL DEFAULT '0' ,
  `salle_id` INT(11) NOT NULL DEFAULT '0' ,
  `semaines_de_presence` BIGINT(20) NULL DEFAULT NULL ,
  PRIMARY KEY (`creneau_emploi_du_temps_id`, `salle_id`) ,
  INDEX `salle_id` (`salle_id` ASC) ,
  CONSTRAINT `creneau_emploi_du_temps_salle_ibfk_1`
    FOREIGN KEY (`creneau_emploi_du_temps_id` )
    REFERENCES `cahierdetextes`.`creneau_emploi_du_temps` (`id` ),
  CONSTRAINT `creneau_emploi_du_temps_salle_ibfk_2`
    FOREIGN KEY (`salle_id` )
    REFERENCES `cahierdetextes`.`salle` (`id` ))
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `cahierdetextes`.`type_devoir`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahierdetextes`.`type_devoir` (
  `id` INT(11) NOT NULL AUTO_INCREMENT ,
  `label` VARCHAR(255) NULL DEFAULT NULL ,
  `description` VARCHAR(255) NULL DEFAULT NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `cahierdetextes`.`devoir`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahierdetextes`.`devoir` (
  `id` INT(11) NOT NULL AUTO_INCREMENT ,
  `cours_id` INT(11) NULL DEFAULT NULL ,
  `type_devoir_id` INT(11) NULL DEFAULT NULL ,
  `contenu` VARCHAR(255) NULL DEFAULT NULL ,
  `date_creation` DATETIME NULL DEFAULT NULL ,
  `date_modification` DATETIME NULL DEFAULT NULL ,
  `date_validation` DATETIME NULL DEFAULT NULL ,
  `date_due` DATE NULL DEFAULT NULL ,
  `temps_estime` INT(11) NULL DEFAULT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `cours_id` (`cours_id` ASC) ,
  INDEX `type_devoir_id` (`type_devoir_id` ASC) ,
  CONSTRAINT `devoir_ibfk_1`
    FOREIGN KEY (`cours_id` )
    REFERENCES `cahierdetextes`.`cours` (`id` ),
  CONSTRAINT `devoir_ibfk_2`
    FOREIGN KEY (`type_devoir_id` )
    REFERENCES `cahierdetextes`.`type_devoir` (`id` ))
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `cahierdetextes`.`devoir_ressource`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahierdetextes`.`devoir_ressource` (
  `devoir_id` INT(11) NOT NULL ,
  `ressource_id` INT(11) NOT NULL ,
  PRIMARY KEY (`devoir_id`, `ressource_id`) ,
  INDEX `devoir_ressource_ressource_id_devoir_id_index` (`ressource_id` ASC, `devoir_id` ASC) ,
  CONSTRAINT `devoir_ressource_ibfk_1`
    FOREIGN KEY (`devoir_id` )
    REFERENCES `cahierdetextes`.`devoir` (`id` ),
  CONSTRAINT `devoir_ressource_ibfk_2`
    FOREIGN KEY (`ressource_id` )
    REFERENCES `cahierdetextes`.`ressource` (`id` ))
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `cahierdetextes`.`devoir_todo_item`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahierdetextes`.`devoir_todo_item` (
  `id` INT(11) NOT NULL AUTO_INCREMENT ,
  `devoir_id` INT(11) NULL DEFAULT NULL ,
  `eleve_id` INT(11) NULL DEFAULT NULL ,
  `date_fait` DATETIME NULL DEFAULT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `devoir_id` (`devoir_id` ASC) ,
  CONSTRAINT `devoir_todo_item_ibfk_1`
    FOREIGN KEY (`devoir_id` )
    REFERENCES `cahierdetextes`.`devoir` (`id` ))
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `cahierdetextes`.`schema_info`
-- -----------------------------------------------------
CREATE  TABLE IF NOT EXISTS `cahierdetextes`.`schema_info` (
  `version` INT(11) NOT NULL DEFAULT '0' )
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;

USE `cahierdetextes` ;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
