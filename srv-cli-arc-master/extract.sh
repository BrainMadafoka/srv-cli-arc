#! /bin/bash

function mode-vsh-extract() {

echo "[Server] You asked for the extraction of the following archive(s): $archive"


  ARCHIVE=archives/$archive

  mkdir temporary_files
  
  #cat $ARCHIVE | grep "directory [A-Za-z0-9]*/" | sed "s/directory //g" > mydirectories.txt
  #sed -E 's/^directory ([A-Za-z0-9/]*)\r?$/\1/;t;d' $ARCHIVE > mydirectories.txt
  sed -e '/^directory [A-Za-z0-9]*/!d' -e 's/^directory //' -e 's/\r$//' $ARCHIVE > mydirectories.txt

  xargs -d'\n' mkdir -p < mydirectories.txt
  #xargs -I {} mkdir -p "{}" < mydirectories.txt

  x=$(cat $ARCHIVE | sed -n '1p' | cut -f2 -d ':' | sed 's/\r$//' )
  y=$(cat $ARCHIVE | wc -l)

  echo " ici cest a : $x"
  echo " ici cest b : $y"

  while [ $x -le $y ]; do
  FILE_BODY=$(cat $ARCHIVE | sed -n $x'p')
  echo "$FILE_BODY" >> temporary_files/FILES_BODY.txt
  let "x++"
  done

  B=0
  while read one_of_the_paths; do
    THE_PATH=$one_of_the_paths
    
    if [ $B -eq 0 ];then
    FILES_AND_DIRS_RIGHTS=$(cat $ARCHIVE | sed -n '4 ,7p')
    elif [ $B -eq 1 ];then
    FILES_AND_DIRS_RIGHTS=$(cat $ARCHIVE | sed -n '10 ,13p')
    elif [ $B -eq 2 ];then
    FILES_AND_DIRS_RIGHTS=$(cat $ARCHIVE | sed -n '16p')
    elif [ $B -eq 3 ];then
    FILES_AND_DIRS_RIGHTS=$(cat $ARCHIVE | sed 's/.*$//g')
    elif [ $B -eq 4 ];then
    FILES_AND_DIRS_RIGHTS=$(cat $ARCHIVE | sed 's/.*$//g')
    elif [ $B -eq 5 ];then
    FILES_AND_DIRS_RIGHTS=$(cat $ARCHIVE | sed -n '23p')
    fi
    
    let "B++"


    #FILES_AND_DIRS_RIGHTS=$(awk -v THE_PATH=$THE_PATH'$' '$0~THE_PATH{flag=1;next}/@/{flag=0} flag' $ARCHIVE)
   
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
       echo "------------------"
       echo "The server found a directory located in $THE_PATH$files_and_dirs"
       echo "Adding the rights $rights to it..."
       #On retire tout les droit avant de les ajouter
       chmod 000 $THE_PATH'/'$files_and_dirs

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
       

        A=$(echo $THE_PATH | sed 's/.*\([A-Za-Z0-9"/"]\)$/\1/g')
 
        echo "Files dir rights : $files_and_dirs"
        echo "CA CEST LE DEBUTFISH : $files_start"
        echo "CA CEST LE TAILLEFISH : $files_size"
        files_start=$(echo "$files_start" | tr -d $'\r')
        files_size=$(echo "$files_size" | tr -d $'\r')

        if [ $files_size -eq 0 ]; then
  	   	maxtaille=$files_start 
  	  	echo "MAXTAILLE : $maxtaille"
        else
  	   	maxtaille=$(echo "$files_start + $files_size" - 1 | bc)
  	  	echo "MAXTAILLE DANS LE CAS -1 : $maxtaille"
        fi


	   if [ $A == "/" ]; then
               echo "------------------"
               echo "The server found a file located in $THE_PATH$files_and_dirs"
     	       echo "Adding the rights $rights to it..."

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
               echo "------------------"
               echo "The server found a file located in $THE_PATH/$files_and_dirs"
               echo "Adding the rights $rights to it..."

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

#Cleaning...
rm -f mydirectories.txt
rm -rf temporary_files/*
}

mode-vsh-extract
