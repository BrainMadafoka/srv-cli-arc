#! /bin/bash


      nbLignes=$(ls -t ./archives/ | wc -l) 
      echo ""
      echo "-----------------------------------------------------"
      echo "Il y a actuellement $nbLignes archives sur le serveur"
      echo ""
      ls -1t ./archives/
      echo "-----------------------------------------------------"
      echo ""
