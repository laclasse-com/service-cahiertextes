# Controleur de l'application pour les élèves.
#
# Lecture seule, pas d'ajout de fichier possible
# Présentation sous forme de todolist.
#

class EleveController < MainController
  
  set_layout 'default'
  set_layout nil => [:testws]

  def index
    
  end
  
  def testws
    "toto"
  end
end
