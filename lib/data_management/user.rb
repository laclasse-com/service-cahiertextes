# -*- coding: utf-8 -*-

module DataManagement
  # Fonctions de data management relatives aux utilisateurs
  module User
    module_function

    def delete( uid )
      UserParameters.where( uid: uid ).destroy

      DevoirTodoItem.where( eleve_id: uid ).destroy

      Cours.where( enseignant_id: uid ).each do |cours|
        cours.devoirs.each(&:destroy)
        cours.destroy
      end

      CreneauEmploiDuTempsEnseignant.where( enseignant_id: uid ) .all .each do |ce|
        cours = Cours[ce.creneau_emploi_du_temps_id]
        ce.destroy
        cours.destroy if cours.enseignants.empty?
      end
    end

    def merge( _target_uid, _source_uid )
      # UserParameters.where( uid: uid ).destroy

      # DevoirTodoItem.where( eleve_id: uid ).destroy

      # Cours.where( enseignant_id: uid ).each do |cours|
      #   cours.devoirs.each do |devoir|
      #     devoir.destroy
      #   end
      #   cours.destroy
      # end

      # CreneauEmploiDuTempsEnseignant.where( enseignant_id: uid )
      #                               .all
      #                               .each do |ce|
      #   cid = ce.creneau_emploi_du_temps_id
      #   ce.destroy
      #   cid.destroy if cid.enseignants.empty?
      # end
    end
  end
end
