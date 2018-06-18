#! /bin/bash

archive=$1

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
rm -d temporary_files
