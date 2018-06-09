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
# 	CMD arg1 arg2 ... argn                   
#                     
# alors elle invoque la fonction :
#                                                                            
#         commande-CMD arg1 arg2 ... argn                                      
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
