#! /bin/bash

# Ce script implémente un serveur.  
# Le script doit être invoqué avec l'argument :                                                              
# PORT   le port sur lequel le serveur attend ses clients  

if [ $# -ne 2 ]; then
    echo "usage: $(basename $0) SERVEUR PORT"
    exit -1
fi

SERVEUR="$1"
PORT="$2"
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

    echo "Bienvenue sur le serveur d'archive."
    echo ""
    local cmd args serv port archive
    while true; do
	read cmd args serv port archive || exit -1
        if [ ! $port = $PORT ] || [ ! $serv = $SERVEUR ];then
        echo "Serveur ou port incorrect"
	echo ""
        else
	fun="mode-$cmd$args" #pour list
        
	
	if [ "$(type -t $fun $args)" = "function" ]; then

		if [ -z $serv ]; then
		    echo ""
		    echo "Il manque un nom de serveur"
		    echo "---------------------------"

		elif [ -z $port ]; then
		   echo ""
	           echo "Il manque un numéro de port"
		   echo "---------------------------"

		else
		    if [ $args = "-extract" ] || [ $args = "-browse" ]; then	 #Si extract ou browse, demande un nom archive 
		        if [ -z $archive ]; then
		            echo ""
			    echo "Veuillez insérer une archive !"
		            echo "------------------------------"
			else
			    $fun
			fi
		    else				   	  
			$fun
		    fi
		fi			
	else
	    if [ $cmd == "clear" ]; then
		clear
	    elif [ $cmd == "What_time_?" ] || [ $cmd == "calendar" ];then
		nowAdate 			########### ajout
	    elif [ $cmd == "help" ];then
		mode-vsh-help
	    elif [ $cmd == "quit" ];then
	        echo "Au revoir et merci !"
		exit	
	    else
	    	mode-non-compris $fun $args
	    fi
	fi
fi
    done

}

# Les fonctions implémentant les différentes commandes du serveur

function nowAdate(){ 				########### ajout
	datejour=$(date +"%A %d %B (%d/%m/%G)")
	datejheure=$(date +"%T")
	echo ""
	echo "----------------------------------"
	echo "Nous sommes $datejour, il est $datejheure."
	echo ""
	cal
	echo "----------------------------------"
	echo ""
}

function mode-vsh-list(){
      bash ./vsh-list.sh $1 $2
}

function mode-vsh-browse(){
     bash ./vsh-browse.sh $archive
}

function mode-vsh-extract() {
      bash ./vsh-extract.sh $archive
}

function mode-vsh-help(){
      echo ""
      echo "-------------------------------------------------------"
      echo ""
      cat help.txt
      echo "-------------------------------------------------------"

}

function mode-non-compris () {
   echo "-------------------------------------------------"
   echo "Ce mode n'existe pas , vous avez le choix entre :"
   echo ""
   echo "    vsh -list "
   echo "    vsh -extract "
   echo "    vsh -browse "
   echo "    quit "
   echo "    clear "
   echo "    calendar (ou What_time_?)"
   echo "    help pour plus d'informations."
   echo "-------------------------------------------------"
}


# On accepte et traite les connexions

accept-loop

