'use strict';

angular.module('cahierDeTextesClientApp')
  .service('Documents',
           ['$http', '$q', 'URL_DOCS', 'Annuaire',
            function($http, $q, URL_DOCS, Annuaire) {
              let Documents = this;
              let cdt_folder_name = 'Cahier de textes.ct';

              Documents.list_files = _.memoize(function(root) {
                let params = {
                  cmd: 'open',
                  target: ''
                };
                if (root == undefined) {
                  params.tree = 1;
                } else {
                  params.target = root;
                }
                return $http.get(`${URL_DOCS}/api/connector`, { params: params });
              });

              Documents.mkdir = function(parent_hash, name) {
                let params = {
                  cmd: 'mkdir',
                  target: parent_hash,
                  name: name
                };
                return $http.get(`${URL_DOCS}/api/connector`, { params: params });
              }

              Documents.rm = function(hashes) {
                let params = {
                  cmd: 'rm',
                  'targets[]': hashes
                };
                return $http.get(`${URL_DOCS}/api/connector`, { params: params });
              }

              Documents.get_ctxt_folder_hash = function(regroupement) {
                let structure,
                structure_root,
                regroupements_root,
                regroupement_root,
                cdt_root;

                let error_handler = function error(response) { return $q.reject(response); };

                switch (regroupement.type) {
                case 'CLS':
                case 'GRP':
                  return Annuaire.get_structure(regroupement.structure_id)
                    .then(function success(response) {
                      structure = response.data;

                      return Documents.list_files();
                    }, error_handler)
                    .then(function success(response) {
                      structure_root = _(response.data.files).findWhere({ phash: null, name: structure.name });

                      return Documents.list_files(structure_root.hash);
                    }, error_handler)
                    .then(function success(response) {
                      regroupements_root = _(response.data.files).findWhere({ phash: structure_root.hash, name: regroupement.type == 'CLS' ? 'classes' : 'groupes' });

                      return Documents.list_files(regroupements_root.hash);
                    }, error_handler)
                    .then(function success(response) {
                      regroupement_root = _(response.data.files).findWhere({ phash: regroupements_root.hash, name: regroupement.name });

                      return Documents.list_files(regroupement_root.hash);
                    }, error_handler)
                    .then(function success(response) {
                      cdt_root = _(response.data.files).findWhere({ phash: regroupement_root.hash, name: cdt_folder_name });

                      if (cdt_root == undefined) {
                        return Documents.mkdir(regroupement_root.hash, cdt_folder_name)
                          .then(function success(response) {
                            return response.data.added[0].hash;
                          }, error_handler)
                      } else {
                        return cdt_root.hash;
                      }
                    }, error_handler);
                case 'GPL':
                  return Documents.list_files()
                    .then(function success(response) {
                      regroupement_root = _(response.data.files).findWhere({ phash: null, name: regroupement.name });

                      return Documents.list_files(regroupement_root.hash);
                    }, error_handler)
                    .then(function success(response) {
                      cdt_root = _(response.data.files).findWhere({ phash: regroupement_root.hash, name: cdt_folder_name });

                      if (cdt_root == undefined) {
                        return Documents.mkdir(regroupement_root.hash, cdt_folder_name)
                          .then(function success(response) {
                            return response.data.added[0].hash;
                          }, error_handler)
                      } else {
                        return cdt_root.hash;
                      }
                    }, error_handler);
                default: console.log('unknown group type');
                }
              };

              Documents.ajout_au_cahier_de_textes = function(classe, node) {
                return Documents.get_ctxt_folder_hash(classe)
                  .then(function(ctxt_folder_hash) {
                    let params = {
                      cmd: 'paste',
                      'targets[]': node.hash,
                      'renames[]': node.name,
                      dst: ctxt_folder_hash,
                      cut: false
                    };

                    return $http.get(`${URL_DOCS}/api/connector`, { params: params });
                  })
                  .then(function success(response) {
                    return response.data;
                  });
              };

              Documents.upload_dans_cahier_de_textes = function(classe, fichiers) {
                return Documents.get_ctxt_folder_hash(classe)
                  .then(function(ctxt_folder_hash) {
                    return $q.all(_(fichiers).map(function(file) {
                      let form_data = new FormData();
                      form_data.append('cmd', 'upload');
                      form_data.append('target', ctxt_folder_hash);
                      form_data.append('upload[]', file);
                      form_data.append('renames[]', file.name);

                      return $http.post(`${URL_DOCS}/api/connector`,
                                        form_data,
                                        {
                                          headers: { 'Content-Type': undefined },
                                          transformRequest: angular.identity
                                        }
                                       );
                    }))
                      .then(function(response) {
                        return response;
                      });
                  });
              };
            }
  ]);
