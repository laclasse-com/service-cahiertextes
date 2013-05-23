delete from `cahier_textes`;
delete from `plage_horaire`;
delete from `ressource`;
delete from `cours`;
delete from `type_devoir`;
delete from `devoir`;

INSERT INTO `cahiertxt`.`type_devoir` (`id`, `lib`, `description`) VALUES (1, 'DS', 'Devoir surveillé');
INSERT INTO `cahiertxt`.`type_devoir` (`id`, `lib`, `description`) VALUES (2, 'DM', 'Devoir à la maison');
INSERT INTO `cahiertxt`.`type_devoir` (`id`, `lib`, `description`) VALUES (3, 'Leçon', 'Leçon à apprendre');
INSERT INTO `cahiertxt`.`type_devoir` (`id`, `lib`, `description`) VALUES (4, 'Exposé', 'Exposé à préparer');
INSERT INTO `cahiertxt`.`type_devoir` (`id`, `lib`, `description`) VALUES (5, 'Recherche', 'Recherche à faire');
INSERT INTO `cahiertxt`.`type_devoir` (`id`, `lib`, `description`) VALUES (6, 'Exercice', 'Exercice à faire');


insert into ressource values (1,'Ressource #1', 12345);
insert into ressource values (2,'Ressource #2', 67890);


INSERT INTO `cahiertxt`.`plage_horaire` (`id`) VALUES ('M1');
INSERT INTO `cahiertxt`.`plage_horaire` (`id`) VALUES ('M2');
INSERT INTO `cahiertxt`.`plage_horaire` (`id`) VALUES ('M3');
INSERT INTO `cahiertxt`.`plage_horaire` (`id`) VALUES ('M4');
INSERT INTO `cahiertxt`.`plage_horaire` (`id`) VALUES ('M5');
INSERT INTO `cahiertxt`.`plage_horaire` (`id`) VALUES ('S1');
INSERT INTO `cahiertxt`.`plage_horaire` (`id`) VALUES ('S2');
INSERT INTO `cahiertxt`.`plage_horaire` (`id`) VALUES ('S3');
INSERT INTO `cahiertxt`.`plage_horaire` (`id`) VALUES ('S4');
INSERT INTO `cahiertxt`.`plage_horaire` (`id`) VALUES ('S5');


INSERT INTO `cahier_textes` VALUES ('1', '1', '6E1', '2011', '2012', now(), false);
INSERT INTO `cahier_textes` VALUES ('2', '2', '6E2', '2011', '2012', now(), false);
INSERT INTO `cahier_textes` VALUES ('3', '3', '6E3', '2011', '2012', now(), false);
INSERT INTO `cahier_textes` VALUES ('4', '4', '6E4', '2011', '2012', now(), false);
INSERT INTO `cahier_textes` VALUES ('5', '5', '6E5', '2011', '2012', now(), false);
INSERT INTO `cahier_textes` VALUES ('6', '6', '6E1', '2012', '2013', now(), false);
INSERT INTO `cahier_textes` VALUES ('7', '7', '6E2', '2012', '2013', now(), false);
INSERT INTO `cahier_textes` VALUES ('8', '8', '6E3', '2012', '2013', now(), false);
INSERT INTO `cahier_textes` VALUES ('9', '9', '6E4', '2012', '2013', now(), false);
INSERT INTO `cahier_textes` VALUES ('10', '10', '6E5', '2012', '2013', now(), false);



insert into cours values('1', 'VAA60001', '1', '1', 'null', 'M1', 'item #1, CT #1, matiere #1', now(), now(), null, null, false);
insert into cours values('2', 'VAA60001', '1', '1', 'null', 'M2', 'item #2, CT #1, matiere #1', now() - INTERVAL 1 DAY, now() - INTERVAL 1 DAY, now(), null, false);
insert into cours values('3', 'VAA60001', '1', '1', '1', 'M3', 'item #3, CT #1, matiere #1', now() - INTERVAL 2 DAY, now() - INTERVAL 2 DAY, null, now(), false);
insert into cours values('4', 'VAA60001', '1', '1', '1', 'M4', 'item #4, CT #1, matiere #1', now() - INTERVAL 3 DAY, now() - INTERVAL 3 DAY, now(), now(), false);
insert into cours values('5', 'VAA60001', '1', '1', 'null', 'M5', 'item #5, CT #1, matiere #1', now() - INTERVAL 4 DAY, now() - INTERVAL 4 DAY, null, null, false);
insert into cours values('6', 'VAA60002', '2', '1', 'null', 'S1', 'item #6, CT #1, matiere #2', now() - INTERVAL 5 DAY, now() - INTERVAL 5 DAY, now(), null, false);
insert into cours values('7', 'VAA60002', '2', '1', '2', 'S2', 'item #7, CT #1, matiere #2', now() - INTERVAL 1 DAY, now() - INTERVAL 1 DAY, null, null, false);
insert into cours values('8', 'VAA60002', '2', '1', '2', 'S3', 'item #8, CT #1, matiere #2', now() - INTERVAL 2 DAY, now() - INTERVAL 2 DAY, now(), null, false);
insert into cours values('9', 'VAA60002', '3', '1', 'null', 'S4', 'item #9, CT #1, matiere #3', now() - INTERVAL 3 DAY, now() - INTERVAL 3 DAY, null, now(), false);
insert into cours values('10', 'VAA60002', '3', '1', 'null', 'S5', 'item #10, CT #1, matiere #3', now(), now(), now(), now(), false);
insert into cours values('11', 'VAA60002', '3', '2', 'null', 'M2', 'item #11, CT #2, matiere #3', now(), now(), null, null, false);
insert into cours values('12', 'VAA60003', '3', '2', 'null', 'M3', 'item #12, CT #2, matiere #3', now() - INTERVAL 10 DAY, now() - INTERVAL 10 DAY, null, null, false);
insert into cours values('13', 'VAA60004', '3', '2', 'null', 'M4', 'item #13, CT #2, matiere #3', now() - INTERVAL 11 DAY, now() - INTERVAL 11 DAY, null, null, false);
insert into cours values('14', 'VAA60005', '3', '2', 'null', 'M5', 'item #14, CT #2, matiere #3', now() - INTERVAL 12 DAY, now() - INTERVAL 12 DAY, null, null, false);



insert into devoir values (1, 1,2,null,'devoir de type #1, cours #2','null',now() + INTERVAL 7 DAY,now(),null,null);
insert into devoir values (2, 2,4,null,'devoir de type #2, cours #4','5',now() + INTERVAL 7 DAY,now(),now(),null);
insert into devoir values (3, 3,6,null,'devoir de type #3, cours #6','10',now() + INTERVAL 7 DAY,now(),null,now());
insert into devoir values (4, 4,8,null,'devoir de type #4, cours #8','15',now() + INTERVAL 7 DAY,now(),now(),now());
insert into devoir values (5, 5,10,null,'devoir de type #5, cours #10','20',now() + INTERVAL 7 DAY,now(),null,null);
insert into devoir values (6, 6,12,null,'devoir de type #6, cours #12','25',now() + INTERVAL 7 DAY,now(),now(),null);
insert into devoir values (7, 1,14,null,'devoir de type #1, cours #14','30',now() + INTERVAL 7 DAY,now(),null,null);
insert into devoir values (8, 2,2,1,'devoir de type #2, cours #2','60',now() + INTERVAL 15 DAY,now(),now(),now());
insert into devoir values (9, 3,4,1,'devoir de type #3, cours #4','90',now() + INTERVAL 15 DAY,now(),null,now());
insert into devoir values (10, 4,6,2,'devoir de type #4, cours #6','120',now() + INTERVAL 15 DAY,now(),now(),null);
