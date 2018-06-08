#!/bin/bash

# Création de la fonction vsh_list() permettant de lister les archives dans le dossier archives
#
# Résultat souhaité : 
#
# Il y a actuellement n archives.
#
# archive1
# archive2
# archive3
# archive4


vsh_list(){

      nbLignes=$(ls -t ./archives/ | wc -l) # retourne le nombre de lignes soit le nombres d'archives sur le serveur.     
      echo "\nIl y a actuellement $nbLignes archives.\n"
      ls -1t ./archives/
      echo ""
      
}
