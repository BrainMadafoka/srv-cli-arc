#! /bin/bash


      nbLignes=$(ls -t ./archives/ | wc -l) # retourne le nombre de lignes soit le nombres d'archives sur le serveur.     
      echo ""
      echo "-----------------------------------------------------"
      echo "Il y a actuellement $nbLignes archives sur le serveur"
      echo ""
      ls -1t ./archives/
      echo "-----------------------------------------------------"
      echo ""
