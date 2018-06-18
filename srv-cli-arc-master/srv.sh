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
	    elif [ $cmd == "help" ];then
		mode-vsh-help
	    elif [ $cmd == "What_time_?" ] || [ $cmd == "calendar" ];then
		nowAdate 			########### ajout
	    elif [ $cmd == "help" ];then
		mode-vsh-help
	    elif [ $cmd == "quit" ];then
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

function mode-vsh-browse(){

	declare -r archive_dir="archives"
	declare -r arch="$archive_dir/$archive"
	declare -r root=$(grep ^directory $arch | sed 's/directory //g' | awk -F "/" '{print $1}' | head -1)
	working_dir=$root


        ARCHIVE=archives/$archive

	if [ ! -e $ARCHIVE ];then
	  echo ""
	  echo "L'archive $archive n'est pas présente sur le serveur."
	  echo "------------------------------------------------------"
	  echo ""
	else
	   echo ""
	   echo "Lutte contre le DDos, merci de patientez..."  ########### ajout
	   #sleep 5
	   echo ""
	   echo "Bienvenue dans le mode browse. Tapez 'help' pour plus d'informations"
	   echo ""


	function get_absolute_path(){
	    path=$1
		if [ $(echo $path | grep "^/") ]; then	#absolute path
			path=$path
		else
			path="$working_dir/$path"
		fi

	    #remove '/' duplicates
	    path=$(echo $path | sed -e 's/\/\{2,\}/\//g')
	    #remove './''
	    path=$(echo $path | sed -e 's/\/\.\//\//g');
	    #replace 'A/B/../C' by 'A/C'
	    path=$(echo $path | sed -e 's/[^\.\/]\{1,\}\/\.\.\///g');
	    #remove trailing slashes and replace duplicates
	    path=$(echo $path | sed -e 's:/*$::')

		echo $path
	}

	function vsh_cd(){

	    if [ $arg == "/" ];then
		working_dir=$root
            elif [ $arg == ".." ];then
		       if [ ! $sauvegarde_dir == $root ];then
		            working_dir=$sauvegarde_dir
		            while [[ ! $working_dir == *"/" ]];do
		            working_dir=$(echo $working_dir | sed 's~\(.*\).$~\1~g')
		            done
		            working_dir=$(echo $working_dir | sed 's~\(.*\).$~\1~g')
		            sauvegarde_dir=$working_dir
                       else
                            echo ""
                            echo "Impossible de remonter plus haut dans l'arborescence , vous etes a la racine de l'archive"
                            echo ""
                       fi

	    else
		    path_save=$arg # !! arg et pas args
		    path=$(get_absolute_path $1)

		    if [ $(grep -c "^directory $path" $arch) -gt 0 ]; then
			working_dir=$path
                        sauvegarde_dir=$working_dir
		    else
			echo ""
			echo "$path_save : n'est pas un répertoire"
			echo ""
		    fi
	    fi
	}

	function vsh_pwd(){
	    echo "/$working_dir"
	}


	function vsh_ls(){
	    path=$(get_absolute_path $1)

	    dir=$(grep $path $arch | sed "s:directory $path/::g" | sed "s:directory $root::g" | sed 'y;/;:;' | awk -F":" '{print $1}' | awk '!a[$0]++' | sed '/^$/d' | sed 's:$:/:g') 
	    working_dir=$(echo $path | sed 's:/:\\/:g' )
	    files=$(awk "/^directory $working_dir(\/$|$)/,/^@$/ {print}" $arch | awk 'NF==5 && !/x/ {print $1}' )
	    exe=$(awk "/^directory $working_dir(\/$|$)/,/^@$/ {print}" $arch | awk 'NF==5 && /x/ {print $1}' | sed 's/$/*/g' )
	    working_dir=$(echo $path | sed 's:\\/:/:g' )
	    echo $dir $exe $files
	}

	function vsh_cat(){
	    right=$(grep $1 $arch | cut -d ' ' -f2 | cut -c1)
	    #echo "right $right"

	    if [[ $right == -* ]];then
	    	arg=$1
	    	#path=$(cat /tmp/projet_path.txt)
	    	header_end=$(grep -n ^@$ $arch | tail -1 | awk -F: '{print $1}')
	    	file_start=$(grep $arg $arch | awk '{print $4}' )
	    	file_size=$(grep $arg $arch | awk '{print $5}' )
	    	true_file_start=$((file_start + header_end))
	    	true_file_end=$((file_start + file_size + header_end - 1))
	    	sed -n "${true_file_start},${true_file_end}p" $arch
	    else
	    	echo ""
	    	echo "$1 : n'est pas un fichier ou n'existe pas."
	    	echo ""
	    fi
	}

   function vsh_rm {
    arg=$1
    directory=$(grep ^directory $arch)               # Récupération des chemins des dossiers de l'archive


    # Check si l'argument est un chemin absolu
    if [[ "$arg" = *"$root"* ]]
        then
            echo "Suppression par chemin absolu de "$arg
            echo "directory "$directory""


            # Check si l'argument est dossier
            if [[ "$directory" = *"$arg"* ]]
                then
                    echo "Suppression du dossier "$arg
                    escaped_arg=$(echo $arg | sed 's:/:\\/:g' )             # Préparation de $arg pour sed et awk              


                    # Check récursif si le dossier contient un sous-dossier et placement dans ce sous-dossier
                    while [[ $(sed -n "/^directory $escaped_arg\(\/$\|$\)/,/^@$/{/^directory $escaped_arg/d; /^@$/d; p;}" $arch | awk 'NR==1 {print NF}' ) = '3' ]] 
                    do
                        sub_dir=$(sed -n "/^directory $escaped_arg\(\/$\|$\)/,/^@$/{/^directory $escaped_arg/d; /^@$/d; p;}" $arch | awk 'NR==1 {print $1}' )                # Récupération du nom du sous-dossier
                        arg=$arg"/"$sub_dir
                        echo "Appel de rm dans le sous-dossier " $arg
                        echo ""
                        vsh_rm $arg
                    done


                    # Suppression des fichiers contenus dans le dossier
                    get_contained_files             # Récupération des fichiers contenus dans le dossier


                    # Check si le dossier contient encore des fichiers
                    while [[ "$contained_files" =~ [0-9] ]]
                    do
                        echo "Le dossier contient "$(echo $contained_files | awk '{print $1}')                        
                        get_header_end              # Récupération de la fin du header de l'archive
                        file_size=$(echo $contained_files | awk '{print $5}' )              # Récupération de la taille du fichier


                        # Check si le fichier est vide
                        if [[ "$file_size" = "0" ]]
                            then echo "Le fichier est vide. Il n'y a rien à supprimer."
                        else                            
                            delete_file_content             # Suppression du contenu du fichier
                        fi
                        delete_file             # Suppression du fichier dans le header
                        get_contained_files             # Update de $contained_files maintenant que le fichier est supprimé
                    done


                    # Suppression du dossier et de son contenu pour se débarasser de @ et des éventuels restes de sous-dossiers
                    echo "Suppression de "$arg
                    sed -i "/^directory $escaped_arg\(\/$\|$\)/,/^@$/ {/^directory $escaped_arg/d; /^@$/d; d;}" $arch
                       
                    
                    # Suppression du sous-dossier ou du dossier s'il n'a plus de sous-dossier
                    sub_dir=$(sed -n "/^directory $escaped_arg\(\/$\|$\)/,/^@$/{/^directory $escaped_arg/d; /^@$/d; p;}" $arch | awk 'NR==1 {print $1}' )                # Récupération du sous-dossier


                    #Check s'il y a un sous-dossier
                    if [[ "$sub_dir" =~ [A-Za-z0-9] ]]
                        then
                            delete_sub_dir              # Suppression du sous-dossier
                            arg=$(echo $arg | sed "s/$sub_dir//g")              # Mise à jour de $arg
                    else
                        delete_last_dir             # Suppression du dossier
                        arg=$(echo $arg | sed "s/$last_dir//g")             # Mise à jour de $arg    
                    fi

                    arg=$(echo $arg | sed "s:/$::g")                # Mise à jour de $arg (ponction du dernier slash)
                    escaped_arg=$(echo $arg | sed 's:/:\\/:g')              # Mise à jour de $escaped_arg


            # Si l'argument est un fichier
            else
                echo "Suppression du fichier "$arg                
                escaped_arg=$(echo $arg | sed 's:/:\\/:g' )             # Création de escaped_arg pour sed et awk
                get_header_end              # Récupération de la fin du header de l'archive
                file_to_delete=$(echo $escaped_arg | awk -F"/" '{print $NF}')               # Récupération du fichier à supprimer 
                file_to_delete=$(grep $file_to_delete $arch)             # Récupération des caractéristiques du fichier
                file_size=$(echo $file_to_delete | awk '{print $5}' )               # Récupération du nombre de lignes du fichier


                # Check si le fichier est vide
                if [[ "$file_size" = "0" ]]
                    then echo $(echo $file_to_delete | awk '{print $1}')" est vide."


                # Si le fichier n'est pas vide
                else                            
                    file_start=$(echo $file_to_delete | awk '{print $4}' )              # Récupération du début du contenu du fichier                 
                    true_file_start=$((file_start + header_end))                # Mise à jour du début avec la fin du header
                    true_file_end=$((file_start + file_size + header_end - 1))              # Récupération de la fin du contenu du fichier
                    echo "Suppression de "$file_size" lignes"
                    sed -i "${true_file_start},${true_file_end}d" $arch              # Suppression du contenu du fichier
                fi


                # Suppression du fichier dans le header
                file_to_delete_1st=$(echo $file_to_delete | awk '{print $1}')               # Récupération du nom du fichier    
                sed -i "/$file_to_delete_1st/d" $arch                # Suppression du fichier dans le header
            fi


    # Si l'argument est un chemin relatif
    else 
        arg=$(get_absolute_path $1) 
        #arg=$path"/"$arg                # Transformation du chemain relatif en chemin absolu
        echo "Transformation en chemin absolu : " $arg
        vsh_rm $arg             # Appel de vsh_rm pour l'argument avec le chemin absolu
    fi
    
}

	function delete_file_content {
	file_start=$(echo $contained_files | awk '{print $4}' )                        
	true_file_start=$((file_start + header_end))
	true_file_end=$((file_start + file_size + header_end - 1))
	echo "Suppression du contenu de "$(echo $contained_files | awk '{print $1}')
	sed -i "${true_file_start},${true_file_end}d" $arch 
	}

	function delete_file {
	    contained_files_1st=$(echo $contained_files | awk '{print $1}')             # Récupération du nom du fichier dans le dossier
	    sed -i "/^$contained_files_1st /d" $arch                                 
	    echo "Suppression de "$contained_files_1st
	}

	function get_contained_files {
	    contained_files=$(sed -n "/^directory $escaped_arg\(\/$\|$\)/,/^@$/{/^directory $escaped_arg/d; /^@$/d; p;}" $arch | awk 'NF==5 {print}' | awk 'NR==1 {print}')              # Récupération du nom du fichier dans le dossier
	}

	function get_header_end {
	    header_end=$(grep -n ^@$ $arch | tail -1 | awk -F: '{print $1}')             # Récupération de la fin du header
	}

	function delete_last_dir {
	    last_dir=$(echo $escaped_arg | awk -F'/' '{print $NF}')             # Récupération du nom du dossier
	    sed -i "/^$last_dir /d" $arch                # Suppression du dossier dans le header
	    echo "Suppression de "$last_dir" dans le header"
	}

	function delete_sub_dir {
	    echo "Suppression de "$sub_dir" dans le header"
	    sed -i "/^$sub_dir /d" $arch 
	}



   while true; do
   printf "vsh:> "
   read commande arg # arg et pas args

   case $commande in
		"pwd")
			vsh_pwd;;
		"ls")
			vsh_ls $arg;;
		"cd")
			vsh_cd $arg;;
		"cat")
			vsh_cat $arg;;
		"rm")
			vsh_rm $arg;;
		"clear")
			clear;;
		"help")
			mode-vsh-help;;
		"calendar")
			nowAdate;;
		"What_time_?")
			nowAdate;;
		"quit")
			echo "Mode browse quitté" 	########### ajout
			echo "" 			########### ajout
			break;;
		*)
			echo "Merci de rentrer une des commandes suivantes : pwd, ls, cd, cat, rm, clear,help, calendar ou What_time_?, quit.";;
   esac
   done
fi
}


function mode-vsh-list(){
      nbLignes=$(ls -t ./archives/ | wc -l) # retourne le nombre de lignes soit le nombres d'archives sur le serveur.     
      echo ""
      echo "-----------------------------------------------------"
      echo "Il y a actuellement $nbLignes archives sur le serveur"
      echo ""
      ls -1t ./archives/
      echo "-----------------------------------------------------"
      echo ""
}

function mode-vsh-help(){
      echo ""
      echo "-------------------------------------------------------"
      echo ""
      cat help.txt
      echo "-------------------------------------------------------"

}

function mode-vsh-extract() {
	echo "------------------------------------------------------"
	echo "Vous avez demandé l'extraction de l'archive suivante : $archive"

	ARCHIVE=archives/$archive

	if [ ! -e $ARCHIVE ];then
	  echo ""
	  echo "L'archive $archive n'est pas présente sur le serveur."
	  echo "------------------------------------------------------"
	  echo ""
	else
	  echo "Traitement en cours.."
	  echo ""


	  mkdir temporary_files
	  
	  #cat $ARCHIVE | grep "directory [A-Za-z0-9]*/" | sed "s/directory //g" > mydirectories.txt
	  #sed -E 's/^directory ([A-Za-z0-9/]*)\r?$/\1/;t;d' $ARCHIVE > mydirectories.txt
	  sed -e '/^directory [A-Za-z0-9]*/!d' -e 's/^directory //' -e 's/\r$//' $ARCHIVE > mydirectories.txt

	  xargs -d'\n' mkdir -p < mydirectories.txt
	  #xargs -I {} mkdir -p "{}" < mydirectories.txt

	  x=$(cat $ARCHIVE | sed -n '1p' | cut -f2 -d ':' | sed 's/\r$//' )
	  y=$(cat $ARCHIVE | wc -l)

	  while [ $x -le $y ]; do
	  FILE_BODY=$(cat $ARCHIVE | sed -n $x'p')
	  echo "$FILE_BODY" >> temporary_files/FILES_BODY.txt
	  let "x++"
	  done

	  B=1
	  while read one_of_the_paths; do
	    THE_PATH=$one_of_the_paths

	    direc=$(grep -n directory $ARCHIVE | sed -n "$B p" | awk -F":" '{print $1}')         
            true_direc=$(echo "$direc" + 1 | bc)
            arobase_associe=$(grep -n ^@$ $ARCHIVE | sed -n "$B p" | awk -F":" '{print $1}')
            true_arobase=$(echo "$arobase_associe" - 1 | bc)            
            FILES_AND_DIRS_RIGHTS=$(cat $ARCHIVE | sed -n "$true_direc , $true_arobase p")
            
            let "B++"

            debut_cara=$(echo $FILES_AND_DIRS_RIGHTS | cut -c1)

            if [[ $debut_cara == "@" ]];then
                 FILES_AND_DIRS_RIGHTS=""
            else 
                 FILES_AND_DIRS_RIGHTS=$FILES_AND_DIRS_RIGHTS
            fi  

	   
	    RIGHTS=$(echo "$FILES_AND_DIRS_RIGHTS" | cut -f2 -d ' ')
	    FILES_AND_DIRS=$(echo "$FILES_AND_DIRS_RIGHTS" | cut -f1 -d ' ')
	    FILES_SIZE=$(echo "$FILES_AND_DIRS_RIGHTS" | cut -f5 -d ' ')
	    FILES_START=$(echo "$FILES_AND_DIRS_RIGHTS" | cut -f4 -d ' ')


	    echo "$FILES_AND_DIRS_RIGHTS" > temporary_files/FILES_AND_DIRS_RIGHTS.txt
	    echo "$RIGHTS" > temporary_files/RIGHTS.txt
	    echo "$FILES_AND_DIRS" > temporary_files/FILES_AND_DIRS.txt
	    echo "$FILES_START" > temporary_files/FILES_START.txt
	    echo "$FILES_SIZE" > temporary_files/FILES_SIZE.txt

	    I=1
	    while read lines; do

	    rights=$(cat temporary_files/RIGHTS.txt | sed -n $I'p')
	    files_and_dirs=$(cat temporary_files/FILES_AND_DIRS.txt | sed -n $I'p')
	    files_start=$(cat temporary_files/FILES_START.txt | sed -n $I'p')
	    files_size=$(cat temporary_files/FILES_SIZE.txt | sed -n $I'p')

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

	       oneSlashDir=$(echo $THE_PATH/$files_and_dirs | sed -e 's/\/\{2,\}/\//g') #enleve les doublons de /.
	       echo "----------------------------------------"
	       echo "Le server a trouvé un répertoire situé dans $oneSlashDir"
	       echo "Ajout des droits $rights à ce répertoire.."
	       #On retire tout les droit avant de les ajouter
	       chmod 000 $oneSlashDir

	       chmod u+$user_rights_1 $oneSlashDir
	       chmod u+$user_rights_2 $oneSlashDir
	       chmod u+$user_rights_3 $oneSlashDir

	       chmod g+$group_rights_1 $oneSlashDir
	       chmod g+$group_rights_2 $oneSlashDir
	       chmod g+$group_rights_3 $oneSlashDir

	       chmod o+$other_rights_1 $oneSlashDir
	       chmod o+$other_rights_2 $oneSlashDir
	       chmod o+$other_rights_3 $oneSlashDir


	    elif [[ $rights  == -* ]]; then
	       

		A=$(echo $THE_PATH | sed 's/.*\([A-Za-Z0-9"/"]\)$/\1/g')
	 
		files_start=$(echo "$files_start" | tr -d $'\r')
		files_size=$(echo "$files_size" | tr -d $'\r')

		if [ $files_size -eq 0 ]; then
	  	   	maxtaille=$files_start 
		else
	  	   	maxtaille=$(echo "$files_start + $files_size" - 1 | bc)
		fi


		   if [ $A == "/" ]; then
		       echo "----------------------------------------"
		       echo "Le server a trouvé un fichier situé dans $THE_PATH$files_and_dirs"
	     	       echo "Ajout des droits $rights à ce fichier.."

		       touch $THE_PATH$files_and_dirs
		       #On retire tout les droit avant de les ajouter
		       chmod 000 $THE_PATH$files_and_dirs
		       
		       #THE_PATH=$(echo $THE_PATH | cut -f1 -d '$' | sed 's/\([A-Za-Z0-9"/"]\).$/\1/g')
		       chmod u+$user_rights_1 $THE_PATH$files_and_dirs
	      	       chmod u+$user_rights_2 $THE_PATH$files_and_dirs
		       chmod u+$user_rights_3 $THE_PATH$files_and_dirs

		       chmod g+$group_rights_1 $THE_PATH$files_and_dirs
		       chmod g+$group_rights_2 $THE_PATH$files_and_dirs
		       chmod g+$group_rights_3 $THE_PATH$files_and_dirs

		       chmod o+$other_rights_1 $THE_PATH$files_and_dirs
		       chmod o+$other_rights_2 $THE_PATH$files_and_dirs
		       chmod o+$other_rights_3 $THE_PATH$files_and_dirs


		      while [ $files_start -le $maxtaille ]; do
		      cat temporary_files/FILES_BODY.txt | sed -n $files_start'p' >> $THE_PATH$files_and_dirs
		      let "files_start++"
		      done
		    else
		       echo "----------------------------------------"
		       echo "Le server a trouvé un fichier situé dans $THE_PATH/$files_and_dirs"
		       echo "Ajout des droits $rights à ce fichier."

		       touch $THE_PATH'/'$files_and_dirs
		       #On retire tous les droits avant de les ajouter
		       chmod 000 $THE_PATH'/'$files_and_dirs

		       #THE_PATH=$(echo $THE_PATH | cut -f1 -d '$' | sed 's/\([A-Za-Z0-9"/"]\).$/\1/g')
		       chmod u+$user_rights_1 $THE_PATH'/'$files_and_dirs
	      	       chmod u+$user_rights_2 $THE_PATH'/'$files_and_dirs
		       chmod u+$user_rights_3 $THE_PATH'/'$files_and_dirs

		       chmod g+$group_rights_1 $THE_PATH'/'$files_and_dirs
		       chmod g+$group_rights_2 $THE_PATH'/'$files_and_dirs
		       chmod g+$group_rights_3 $THE_PATH'/'$files_and_dirs

		       chmod o+$other_rights_1 $THE_PATH'/'$files_and_dirs
		       chmod o+$other_rights_2 $THE_PATH'/'$files_and_dirs
		       chmod o+$other_rights_3 $THE_PATH'/'$files_and_dirs


		      while [ $files_start -le $maxtaille ]; do
		      cat temporary_files/FILES_BODY.txt | sed -n $files_start'p' >> $THE_PATH'/'$files_and_dirs
		      let "files_start++"
		      done
	       fi

	       
	     fi
	    let "I++"

	    done <temporary_files/FILES_AND_DIRS_RIGHTS.txt


	  done <mydirectories.txt
	fi
#Cleaning...
rm -f mydirectories.txt
rm -rf temporary_files/*
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

