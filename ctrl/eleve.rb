# Controleur de l'application pour les élèves.
#
# Lecture seule, pas d'ajout de fichier possible
# Présentation sous forme de todolist.
#

class EleveController < MainController
  
  set_layout 'default'
  set_layout nil => [:devoirs, :cours]

  def index
    
  end
  
  #
  # Liste des devoirs de l'élève
  #
  def devoirs
    "devoirs"
  end
  
  #
  # Liste des cours de l'élève
  #
  def cours
    "cours"
  end
  
  
end
