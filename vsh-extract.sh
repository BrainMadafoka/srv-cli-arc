#!bin/bash

# Les fonctions sont appelées par le script "server"
# Le dossier "script" et le dossier "archives" sont au même niveau d'arborescence
# Il faut donc régulièrement avoir recours à cd ../archives pour intéragir avec son contenu 

function vsh_extract() {
	
	cd tmp
	dirtmp=$(pwd) # On stocke le chemin absolu vers le dossier tmp
	cd ../../archives
	read input # fichier correspondant à l'archive qui va être traitée, non nécessaire lorsque la fonction sera appelée par server
	echo ""
	asroot=$(pwd) # À changer par le répertoire du client ?

############################################################ 

# tentative première, créée l'abrorescence des dossiers mais c'est tout

	# awk '/^directory/ {print $2}' $input > ../scripts/tmp/tmp-extract # $input sera normalement remplacé par $4, provenant de la commande vsh -extract [serveur] [port] [archive]
	# #cat ../scripts/tmp/tmp-extract # Pour vérifier que le fichier tmp-extract contient bien ce que l'on veut
	# while read line
	# 	do
	#  		mkdir -p $line # crée l'arborescence de dossiers
	#  	done < ../scripts/tmp/tmp-extract
	# rm ../scripts/tmp/tmp-extract

############################################################
	
	hdebut=$(sed '1q' $input | cut -d : -f 1) # la variable hdebut donne la ligne où commence le header de l'archive
	bdebut=$(sed '1q' $input | cut -d : -f 2) # la variable bdebut donne la ligne où commence le body de l'archive
	hend=$(($bdebut-1)) # la variable hend donne la ligne où se termine le header de l'archive
	bend=$(sed -n '$=' $input) # la variable bend donne la ligne où se termine le body de l'archive
	echo ""

	sed -n "$((hdebut)),$((hend))p" $input > $dirtmp/header
	sed -n "$((bdebut)),$((bend))p" $input > $dirtmp/body

	while read -r line
		do 
			if [[ $(echo "$line" | egrep "^directory") ]] # si la ligne commence par "directory", on va créer l'arborescence qui est détaillée dans la suite de la ligne
				then
					if [[ ! -d  $(echo "$line" | cut -d " " -f 2) ]] # pour éviter la re-création d'un dossier plus tard dans l'archive (ce qui ferait perdre les attributions de permission)
						then
							mkdir -p $(echo "$line" | cut -d " " -f 2)
							echo "L'arborescence $(echo "$line" | cut -d " " -f 2) a été créée"
							cd $(echo "$line" | cut -d " " -f 2) # Il faut se placer dans le niveau d'aborescence créé pour pouvoir ensuite créer les fichiers et répertoires du niveau
						else
							echo "L'arborescence $(echo "$line" | cut -d " " -f 2) existe déjà" 
							
							cd $(echo "$line" | cut -d " " -f 2) # Il faut se placer dans le niveau d'aborescence créé pour pouvoir ensuite créer les fichiers et répertoires du niveau
					fi

			# elif [[ "$line" =~ ^\w+\sd ]] # Cette version ne marche pas à cause de la gestion des regex par défaut de bash
			
			elif [[ $(echo "$line" | egrep "^\w+\sd") ]]  # si la ligne contient nom_dossier/espace/d => décrit un répertoire (permissions + taille)
				then
					mkdir -p $(echo "$line" | cut -d " " -f 1)
					echo "Le répertoire $(echo "$line" | cut -d " " -f 1) a été créé"
					# il faudra rajouter les changements de permissions

			elif [[ $(echo "$line" | egrep "\d+\s\d+\s\d+$") ]] # si la ligne finit par 3 nb séparés par des espace => décrit un fichier (permissions + taille + emplacement dans body)
				then
					echo ""
					name=$(echo "$line" | cut -d " " -f 1) # On va affecter à des variables le nom et l'emplacement du contenu du fichier 
						echo "Traitement du fichier $name"
					fdebut=$(echo "$line" | cut -d " " -f 4)
						echo "Ligne de début dans tmp/body : $fdebut"
					flength=$(echo "$line" | cut -d " " -f 5)
						echo "Nombre de lignes dans tmp/body : $flength"
					fend=$((fdebut+flength-1))
						echo "Ligne de fin dans tmp/body : $fend"

					curdir=$(pwd) # On sauvegarde l'emplacement où l'on est pour y envoyer le fichier qui va être créé 
					
					if [[ $flength -eq 0 ]]
						then
							touch $curdir/$name # Si la longueur du fichier vaut 0 on utilise "touch" car le "sed" a tendance à lui implémenter du contenu au vu à cause de la rédaction du code
							echo "Le fichier $name a été créé. C'est un fichier vide."
						else	
							sed -n "$((fdebut)),$((fend))p" $dirtmp/body > $curdir/$name
								echo "Le fichier $name a été créé"
					fi

			elif [[ "$line" =~ ^@ ]]
				then
					cd $asroot
					echo ""
					echo "Retour au répertoire de départ"
					echo $(pwd)
					echo ""

			else
				echo "ÉCHEC" 
			fi
		done < $dirtmp/header


}

vsh_extract # indispensable actuellement pour tester la fonction (vu qu'elle n'est pas encore appelée par server)
