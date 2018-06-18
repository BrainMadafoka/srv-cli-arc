#! /bin/bash

         archive=$1

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
	   echo "Lutte contre le DDos, merci de patientez..."
	   sleep 2
	   echo ""
	   echo "Bienvenue dans le mode browse. Tapez 'help' pour plus d'informations"
	   echo ""

###########################################################################################
#                                     AIDE                                                #
###########################################################################################
	function mode-vsh-help(){
	      echo ""
	      echo "-------------------------------------------------------"
	      echo ""
	      cat help.txt
	      echo "-------------------------------------------------------"

	}


###########################################################################################
#                                     CHEMIN ABSOLU                                       #
###########################################################################################
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

###########################################################################################
#                                          CD                                             #
###########################################################################################

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

###########################################################################################
#                                           PWD                                           #
###########################################################################################

	function vsh_pwd(){
	    echo "/$working_dir"
	}

###########################################################################################
#                                           LS                                            #
###########################################################################################

	function vsh_ls(){
	    path=$(get_absolute_path $1)

	    dir=$(grep $path $arch | sed "s:directory $path/::g" | sed "s:directory $root::g" | sed 'y;/;:;' | awk -F":" '{print $1}' | awk '!a[$0]++' | sed '/^$/d' | sed 's:$:/:g') 
	    working_dir=$(echo $path | sed 's:/:\\/:g' )
	    files=$(awk "/^directory $working_dir(\/$|$)/,/^@$/ {print}" $arch | awk 'NF==5 && !/x/ {print $1}' )
	    exe=$(awk "/^directory $working_dir(\/$|$)/,/^@$/ {print}" $arch | awk 'NF==5 && /x/ {print $1}' | sed 's/$/*/g' )
	    working_dir=$(echo $path | sed 's:\\/:/:g' )
	    echo $dir $exe $files
	}

###########################################################################################
#                                          CAT                                            #
###########################################################################################

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

###########################################################################################
#                                          RM                                             #
###########################################################################################

   function vsh_rm(){
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

                    arg=$(echo $arg | sed "s:/$::g")                # Mise à jour de $arg (supp. du dernier slash)
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

###########################################################################################
#                            Suppression contenu fichier                                  #
###########################################################################################

	function delete_file_content(){
	file_start=$(echo $contained_files | awk '{print $4}' )                        
	true_file_start=$((file_start + header_end))
	true_file_end=$((file_start + file_size + header_end - 1))
	echo "Suppression du contenu de "$(echo $contained_files | awk '{print $1}')
	sed -i "${true_file_start},${true_file_end}d" $arch 
	}

###########################################################################################
#                            Suppression fichier                                          #
###########################################################################################

	function delete_file(){
	    contained_files_1st=$(echo $contained_files | awk '{print $1}')             # Récupération du nom du fichier dans le dossier
	    sed -i "/^$contained_files_1st /d" $arch                                 
	    echo "Suppression de "$contained_files_1st
	}

###########################################################################################
#                            Récupération nom fichier                                     #
###########################################################################################

	function get_contained_files(){
	    contained_files=$(sed -n "/^directory $escaped_arg\(\/$\|$\)/,/^@$/{/^directory $escaped_arg/d; /^@$/d; p;}" $arch | awk 'NF==5 {print}' | awk 'NR==1 {print}')              # Récupération du nom du fichier dans le dossier
	}

###########################################################################################
#                            Récupération fin header                                      #
###########################################################################################

	function get_header_end(){
	    header_end=$(grep -n ^@$ $arch | tail -1 | awk -F: '{print $1}')             # Récupération de la fin du header
	}

###########################################################################################
#                            Suppression dossier dans header                              #
###########################################################################################

	function delete_last_dir(){
	    last_dir=$(echo $escaped_arg | awk -F'/' '{print $NF}')             # Récupération du nom du dossier
	    sed -i "/^$last_dir /d" $arch                # Suppression du dossier dans le header
	    echo "Suppression de "$last_dir" dans le header"
	}

###########################################################################################
#                            Suppression sous dossier                                     #
###########################################################################################

	function delete_sub_dir(){
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
		"quit")
			echo "Mode browse quitté" 	
			echo "" 	
			break;;
		*)
			echo "Merci de rentrer une des commandes suivantes : pwd, ls, cd, cat, rm, clear, help, quit.";;
   esac
   done
fi
