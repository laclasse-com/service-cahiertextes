# Controleur de l'application pour les élèves.
#
# Lecture seule, pas d'ajout de fichier possible
# Présentation sous forme de todolist.
#

class EleveController < MainController
  
  set_layout 'default'
  set_layout nil => [:cours, :devoirs, :params]

  def index
    
  end
  
  #
  # Liste des cours de l'élève
  #
  def cours
    "cours"
  end
  
  #
  # Liste des devoirs de l'élève
  #
  def devoirs
    "devoirs"
  end
  
  #
  # Paramètres chaiers de textes l'élève
  #
  def params
    "Param&egrave;tres d'affichage du cahier de textes de l'&eacute;l&egrave;ve..."
  end
  
end
