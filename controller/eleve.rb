# Controleur de l'application pour les élèves.
#
# Lecture seule, pas d'ajout de fichier possible
# Présentation sous forme de todolist.
#


class EleveController < MainController
  
  set_layout 'default'
  set_layout nil => [:cours, :devoirs, :params]

#THINK : Le point d'entrée est le usr_id, avec lequel on va charcher via un service web, sa classe, ses groupes.
@@cls_id = 1
@@ct = CahierTextes[:regrpnt_id => @@cls_id]

  def index
    
  end
  
  #
  # Liste des cours de l'élève
  #
  def cours
    liste_cours = @@ct.cours
    liste_cours.to_json  
  end
  
  #
  # Liste des devoirs de l'élève
  #
  def devoirs
    #TODO : comprendre comment ça marche sequel quand met-on .all quand le met-on pas ???
    #puts "ct.id=" + @@ct.id.to_s
    #cr = Cours[:cahier_textes_id => @@ct.id]
    #puts cr.to_json
    #liste_devoir = cr.devoir
    #liste_devoir.to_json  
    liste_cours = @@ct.cours
    liste_cours.to_json  

  end
  
  #
  # Paramètres chaiers de textes l'élève
  #
  def params
    "Param&egrave;tres d'affichage du cahier de textes de l'&eacute;l&egrave;ve..."
  end
  
end
