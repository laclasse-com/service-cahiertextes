# -*- coding: utf-8 -*-

require 'nokogiri'

require './models'

def uncrypt_ProNote_XML( xml )
  # xsd_chiffre = Nokogiri::XML::Schema( File.open( "../ConteneurExportChiffre.xsd" ) )
  # edt_chiffre = Nokogiri::XML( File.open( "../Edt_To_LaclasseCom_0134567A.xml" ) )
  
  # p xsd_chiffre.valid?(edt_chiffre) ? "XML chiffré valide :)" : "XML chiffré NON valide :("
  
  return xml
end

def load_ProNote_XML( xml_file, xsd_file=nil )
  edt_clair = Nokogiri::XML( xml_file )

  #TODO: use XSD defined in XML
  # if xsd_file != nil then
  #   xsd = Nokogiri::XML::Schema( xsd_file )
  #   if ! xsd.valid?( edt_clair ) then
  #     p xsd.validate( edt_clair )
  #     return
  #   end
  # end

  code_etablissement = edt_clair.child["UAI"]
  p "Etablissement: " + code_etablissement
  
  # edt_clair.search( "AnneeScolaire" ).each do |node|
  #   if node.name != "text" then
  #     p "## " + node.name
  #     node.keys.each do |attr|
  #       p "  " + attr + ": " + node[attr]
  #     end
  #   end
  # end
  
  # edt_clair.search( "GrilleHoraire" ).each do |node|
  #   print "new " + node.name + "( " +
  #     node["NombrePlacesParJour"] + ", " +
  #     node["DureePlace"] + " )\n" unless node.name == "text"
  # end

  edt_clair.search( "PlacesParJour" ).children.each do
    |place|
    TrancheHoraire.create(label: place["Numero"],
                          debut: place["LibelleHeureDebut"],
                          fin: place["LibelleHeureFin"] ) unless place.name == "text"
  end

  # edt_clair.search( "Matieres" ).children.each do |matiere|
  #   print "new " + matiere.name + "( " +
  #     matiere["Ident"] + ", '" +
  #     matiere["Code"] + ", '" +
  #     matiere["Libelle"] + "' )\n" unless matiere.name == "text"
  # end
  
  # edt_clair.search( "Professeurs" ).children.each do |professeur|
  #   print "new " + professeur.name + "( " +
  #     professeur["Ident"] + ", '" +
  #     professeur["Nom"] + ", '" +
  #     professeur["Prenom"] + ", '" +
  #     professeur["CodePostal"] + "' )\n" unless professeur.name == "text"
  # end
  
  # edt_clair.search( "Classes" ).children.each do |classe|
  #   if classe.name != "text" then
  #     print "new " + classe.name + "( " +
  #       classe["Ident"] + ", '" +
  #       classe["Nom"] + "' )\n"
  #     classe.children.each do |partie_de_classe|
  #       print "  new " + partie_de_classe.name + "( :parent => " + classe["Ident"] + ", " +
  #         partie_de_classe["Ident"] + " )\n" unless partie_de_classe.name == "text"
  #     end
  #   end
  # end
  
  # edt_clair.search( "Groupes" ).children.each do |groupe|
  #   if groupe.name != "text" then
  #     print "new " + groupe.name + "( " +
  #       groupe["Ident"] + ", '" +
  #       groupe["Nom"] + "' )\n"
  #     groupe.children.each do |node|
  #       case node.name
  #       when "PartieDeClasse"
  #         print "  new " + node.name + "( :parent => " + groupe["Ident"] + ", " +
  #           node["Ident"] + " )\n" unless node.name == "text"
  #       when "Classe"
  #         print "  new " + node.name + "( :parent => " + groupe["Ident"] + ", " +
  #           node["Ident"] + " )\n" unless node.name == "text"
  #       end
  #     end
  #   end
  # end
  
  # edt_clair.search( "Salles" ).children.each do |salle|
  #   print "new " + salle.name + "( " + salle["Ident"] + ", '" + salle["Nom"] + "' )\n" unless salle.name == "text"
  # end
  
  # edt_clair.search( "Eleves" ).children.each do |eleve|
  #   print "new " + eleve.name +
  #     "( " + eleve["Ident"] +
  #     ", '" + eleve["Nom"] + "', '" +
  #     ", '" + eleve["Prenom"] + "', '" +
  #     ", '" + (eleve["DateNaissance"] or "") + "', '" +
  #     ", '" + eleve["Sexe"] + "', '" +
  #     ", '" + (eleve["CodePostal"] or "") + "', '" +
  #     ", '" + (eleve["NumeroNational"] or "") + 
  #     "' )\n" unless eleve.name == "text"
  #   eleve.children.each do |node|
  #     case node.name
  #     when "Responsable"
  #       print "  new " + node.name +
  #         "( :eleve => " + eleve["Ident"] + 
  #         ", " + node["Ident"] +
  #         ", " + node["RespLegal"] +
  #         ", '" + node["Nom"] + "', '" +
  #         ", '" + node["Prenom"] + "', '" +
  #         ", '" + (node["Civilite"] or "") + "', '" +
  #         ", '" + node["Adresse1"] + "', '" +
  #         ", '" + node["CodePostal"] + "', '" +
  #         ", '" + node["Ville"] + 
  #         "' )\n" unless node.name == "text"
  #     when "Classe"
  #       print "  link Eleve(" + eleve["Ident"] + ") to Classe(" + node["Ident"] + ") from " + node["DateEntree"] + " to " + node["DateSortie"] + "\n"
  #     when "PartieDeClasse"
  #       print "  link Eleve(" + eleve["Ident"] + ") to PartieDeClasse(" + node["Ident"] + ") from " + node["DateEntree"] + " to " + node["DateSortie"] + "\n"
  #     end
  #   end
  # end
  
  # edt_clair.search( "Cours" ).children.each do |cours|
  #   print "new " + cours.name +
  #     "(" + cours["Jour"] +
  #     ", " + cours["NumeroPlaceDebut"] +
  #     ", " + cours["NombrePlaces"] +
  #     ")\n" unless cours.name == "text" || !cours.has_attribute?("Jour")
  #   cours.children.each do |node|
  #     case node.name
  #     when "Matiere"
  #       print "  :matiere => " + node["Ident"] + "\n"
  #     else
  #       print "  :" + node.name + "[" + node["Ident"] + "] => semaines(" + node["Semaines"] + ")\n" if node.has_attribute?("Ident")
  #     end
  #   end
  # end

end
