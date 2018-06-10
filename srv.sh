#! /bin/bash

# Ce script implémente un serveur.  
# Le script doit être invoqué avec l'argument :                                                              
# PORT   le port sur lequel le serveur attend ses clients  

if [ $# -ne 1 ]; then
    echo "usage: $(basename $0) PORT"
    exit -1
fi

PORT="$1"

# Déclaration du tube

FIFO="/tmp/$USER-fifo-$$"


# Il faut détruire le tube quand le serveur termine pour éviter de
# polluer /tmp.  On utilise pour cela une instruction trap pour être sur de
# nettoyer même si le serveur est interrompu par un signal.

function nettoyage() { rm -f "$FIFO"; }
trap nettoyage EXIT

# on crée le tube nommé

[ -e "$FIFO" ] || mkfifo "$FIFO"


function accept-loop() {
    while true; do
	interaction < "$FIFO" | netcat -l -p "$PORT" > "$FIFO"
    done
}

# La fonction interaction lit les commandes du client sur entrée standard 
# et envoie les réponses sur sa sortie standard. 
#
# 	MODE arg1 arg2 ... argn                   
#                     
# alors elle invoque la fonction :
#                                                                            
#         mode-CMD arg1 arg2 ... argn                                      
#                                                                              
# si elle existe; sinon elle envoie une réponse d'erreur.                     

function interaction() {
    local cmd args
    while true; do
	read cmd args || exit -1
	fun="mode-$cmd"
	if [ "$(type -t $fun)" = "function" ]; then
	    $fun $args
	else
	    mode-non-compris $fun $args
	fi
    done
}

# Les fonctions implémentant les différentes commandes du serveur

function mode-vsh_list(){
      nbLignes=$(ls -t ./archives/ | wc -l) # retourne le nombre de lignes soit le nombres d'archives sur le serveur.     
      echo ""
      echo "Il y a actuellement $nbLignes archives sur le serveur"
      echo ""
      ls -1t ./archives/
      echo ""
}

function mode-vsh-extract() {

    echo "[Server] You asked for the extraction of the following archive(s): $archive"


  ARCHIVE=archives/$archive

  mkdir temporary_files
  cat $ARCHIVE | grep "directory [A-Za-z0-9]*/" | sed "s/directory //g" > mydirectories.txt


  xargs -I {} mkdir -p "{}" < mydirectories.txt



  while read one_of_the_paths; do

    THE_PATH=$one_of_the_paths

    FILES_AND_DIRS_RIGHTS=$(awk -v THE_PATH=$THE_PATH'$' '$0~THE_PATH{flag=1;next}/@/{flag=0} flag' $ARCHIVE)
    RIGHTS=$(echo "$FILES_AND_DIRS_RIGHTS" | cut -f2 -d ' ')
    FILES_AND_DIRS=$(echo "$FILES_AND_DIRS_RIGHTS" | cut -f1 -d ' ')

    echo "$FILES_AND_DIRS_RIGHTS" > temporary_files/FILES_AND_DIRS_RIGHTS.txt
    echo "$RIGHTS" > temporary_files/RIGHTS.txt
    echo "$FILES_AND_DIRS" > temporary_files/FILES_AND_DIRS.txt


    I=1
    while read lines; do

    rights=$(cat temporary_files/RIGHTS.txt | sed -n $I'p')
    files_and_dirs=$(cat temporary_files/FILES_AND_DIRS.txt | sed -n $I'p')

    user_rights_1=$(echo $rights | cut -c2)
    user_rights_2=$(echo $rights | cut -c3)
    user_rights_3=$(echo $rights | cut -c4)

    group_rights_1=$(echo $rights | cut -c5)
    group_rights_2=$(echo $rights | cut -c6)
    group_rights_3=$(echo $rights | cut -c7)

    other_rights_1=$(echo $rights | cut -c8)
    other_rights_2=$(echo $rights | cut -c9)
    other_rights_3=$(echo $rights | cut -c10)



    if [[ $rights == d* ]]; then
       echo "------------------"
       echo "The server found a directory located in $THE_PATH/$files_and_dirs"
       echo "Adding the rights $rights to it..."

       chmod u+$user_rights_1 $THE_PATH'/'$files_and_dirs
       chmod u+$user_rights_2 $THE_PATH'/'$files_and_dirs
       chmod u+$user_rights_3 $THE_PATH'/'$files_and_dirs

       chmod g+$group_rights_1 $THE_PATH'/'$files_and_dirs
       chmod g+$group_rights_2 $THE_PATH'/'$files_and_dirs
       chmod g+$group_rights_3 $THE_PATH'/'$files_and_dirs

       chmod o+$other_rights_1 $THE_PATH'/'$files_and_dirs
       chmod o+$other_rights_2 $THE_PATH'/'$files_and_dirs
       chmod o+$other_rights_3 $THE_PATH'/'$files_and_dirs


    elif [[ $rights  == -* ]]; then
       echo "------------------"
       echo "The server found a file located in $THE_PATH/$files_and_dirs"
       echo "Adding the rights $rights to it..."

       touch $THE_PATH'/'$files_and_dirs

       chmod u+$user_rights_1 $THE_PATH'/'$files_and_dirs
       chmod u+$user_rights_2 $THE_PATH'/'$files_and_dirs
       chmod u+$user_rights_3 $THE_PATH'/'$files_and_dirs

       chmod g+$group_rights_1 $THE_PATH'/'$files_and_dirs
       chmod g+$group_rights_2 $THE_PATH'/'$files_and_dirs
       chmod g+$group_rights_3 $THE_PATH'/'$files_and_dirs

       chmod o+$other_rights_1 $THE_PATH'/'$files_and_dirs
       chmod o+$other_rights_2 $THE_PATH'/'$files_and_dirs
       chmod o+$other_rights_3 $THE_PATH'/'$files_and_dirs
     fi
    let "I++"

    done <temporary_files/FILES_AND_DIRS_RIGHTS.txt


  done <mydirectories.txt

#Cleaning...
#rm -f mydirectories.txt
rm -rf temporary_files/*
}

function mode-non-compris () {
   echo ""
   echo "Ce mode n'existe pas , vous avez le choix entre :"
   echo ""
   echo "vsh_list "
   echo "vsh_extract "
   echo "vsh_browse "
}


# On accepte et traite les connexions

accept-loop
