#!/bin/bash

#gérer la suppression récursive de dossiers avec la fonction deleteDirectory():
#pour supprimer : currentArchive=$(echo "$currentArchive" | grep -v "$contentToDelete")

# Ferme le client si l'utilisateur a oublié de mettre l'archive
if [ -z $4 ]
then
	echo "No archive given"
	echo "Usage : vsh -browse [SERVER_NAME] [PORT] [ARCHIVE_NAME]"
	exit 1
fi

function deleteDirectory() {

	echo "Fichier dans un fichier"
	echo "$1"
	##############
	#args : $1=$toDeletePath (A; A/A1; ...) $2=$toDeleteName (A; A1; ...)
	# toDeleteContent=$(echo "$currentArchive" | awk -v directory="$root/$toDeletePath" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
	#for i in directoryContent
	#if i is type directory
	# iName=$(echo "$i" | cut -d" " -f1)
	# iPath=$(echo "$toDeletePath/$iName")
	#then deleteDirectory iPath iName
	#elsif i is type file; delete i
	#done
	#delete toDelete
	##############
#lorsque l'on veut supprimer un dossier, lancer la fonction avec le chemin du dossier et son nom
#dans la fonction :
#----pour tout le contenu du dossier :
#--------si dossier, on lance la fonction, le dossier et son contenu est supprimé
#--------si fichier, on supprime
#----supprimer le dossier
#le dossier et son contenu on été supprimé
	
}

# Variables locales
currentArchive=$(cat ../archives/$4)
# currentDirectory ne doit jamais finir par "/" sauf lorsqu'on est à la racine
currentDirectory=/
# Pour l'archive exemple, root a la valeur : Exemple/Test
root=$(echo "$currentArchive" | head -n 3 | tail -n 1 | cut -d" " -f2 | sed 's/\/$//') #Récupère la racine de l'archive
headBegin=$(echo "$currentArchive" | head -n 1 | cut -d":" -f1)
bodyBegin=$(echo "$currentArchive" | head -n 1 | cut -d":" -f2)

echo -n "vsh:> "
# Tant que l'utilisateur ne quitte pas le programme
while read input
do
	# On change les arguments pour les gérer avec $1 $2 etc.
	set -- $(echo $input)
	case $1 in

		# Affiche le dossier courant
		"pwd" )
		echo "$currentDirectory"
		;;

		# Affiche les fichiers et dossiers présents dans le dossier courant
		"ls" )

		# Récupérer la ligne dans le header correspondant au fichier courant ainsi que les lignes suivantes jusqu'au prochain @
		directoryContent=$(echo "$currentArchive" | awk -v directory="$root$currentDirectory" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')

		# On sauvegarde IFS et on le change pour la boucle for
		oldIFS=$IFS
		IFS=$'\n'

		# Pour chaque ligne dans le dossier courant, on affiche le nom, / à la fin si dossier, * à la fin si exécutable
		for i in $directoryContent
		do
			name=$(echo "$i" | cut -d" " -f1)
			perm=$(echo "$i" | cut -d" " -f2)
			# On vérifie s'il les permissions commencent par un d
			if (echo "$perm" | egrep -q "^d")
			then
				echo -ne "$name/\t"
			# Sinon on vérifie s'il y a un x dans les permissions
			elif (echo "$perm" | egrep -q "x")
			then
				echo -ne "$name*\t"
			else
				echo -ne "$name\t"
			fi
		done
		echo ""
		# Restauration de IFS
		IFS=$oldIFS
		;;

		# Permet de changer de répertoire
		"cd" )
		path=$2

		# On retire le possible "/" à la fin d'un chemin (sauf si cd /)
		if (echo "$path" | egrep -q "/$")
		then
			path=$(echo "$path" | sed 's/.$//')
		fi

		# On teste si chemin absolu ou relatif
		if (echo "$path" | egrep -q "^/")
		# Chemin absolu
		then
			# On vérifie que le chemin est présent dans l'archive
			# BUG : il y a un bug lorsque l'on rajoute "$" à la fin de la régex, tous les dossiers sont trouvés sauf /A/A2 et /A/A3, le grep récupère donc tous les résultats où le chemin apparaît (ce qui ne gêne pas puisqu'on veut juste vérifier qu'il existe)
			# FIX : enlever le $ à la fin de la régex
			# UPDATE : il y a un espace après A/A2 et A/A3
			# FIX : ajouter " ?$" à la fin de la régex pour gérer la présence d'un possible espace
			if (echo "$currentArchive" | egrep -q "^directory $root$path ?$")
			then
				currentDirectory=$(echo "$path")
			else
				echo "No directory found"
			fi
		# Chemin relatif
		else
			# Si cd
			if [ -z "$path" ]
			then
				currentDirectory=/
			# Si cd ..
			elif [ "$path" = ".." ]
			then
				# Si on est déjà à la racine
				if [ "$currentDirectory" = "/" ]
				then
					# On reste à la racine
					currentDirectory=/
				else
					# On revient au dossier précédent grâce au chemin
					currentDirectory=$(echo "$currentDirectory" | egrep -o ".*/")
					# Si on n'est pas revenu à la racine on retire le "/" de fin
					if [ "$currentDirectory" != "/" ]
					then
						# On enlève le "/" à la fin pour rester cohérent
						currentDirectory=$(echo "$currentDirectory" | sed 's/\/$//')
					fi
				fi
			# Si cd Dossier/Dossier1 etc.
			else
				# À cause des "/", on traite différemment la ligne de texte selon que l'on soit sur la racine ou non
				# Si on est dans la racine
				if [ "$currentDirectory" = "/" ]
				then
					# Si le chemin est présent dans l'archive
					if (echo "$currentArchive" | egrep -q "$root$currentDirectory$path ?$")
					then
						# Pas besoin de rajouter un "/" entre l'origine et la destination
						currentDirectory=$(echo "$currentDirectory$path")
					else
						echo "No directory found"
					fi
				# Si on est ailleurs qu'à la racine
				else
					# Si le chemin est présent dans l'archive
					if (echo "$currentArchive" | egrep -q "$root$currentDirectory/$path ?$")
					then
						# On ajoute le "/" entre l'origine et la destination
						currentDirectory=$(echo "$currentDirectory/$path")
					else
						echo "No directory found"
					fi
				fi
			fi
		fi
		;;

		"cat" )
		echo "commande cat"
		;;

		# Supprime un fichier/dossier
		"rm" )
		toDelete=$2

		if [ -n "$toDelete" ]
		then
			# On retire le possible "/" à la fin d'un chemin (sauf si c'est la racine)
			if (echo "$toDelete" | egrep -q ".+/$")
			then
				toDelete=$(echo "$toDelete" | sed 's/.$//')
	                fi

			# On regarde si l'entité à supprimer existe et est un fichier ou un dossier
			# Chemin absolu
			if (echo "$toDelete" | egrep -q "^/")
			then
				# Si l'entité est la racine
				if [ "$toDelete" = "/" ]
				then
					echo "Are you sure you want to delete everything ? y/n"
					read response
					case $response in

						[yYoO]*)
						currentArchive=''
						;;

						[nN]*)
						echo "Deletion aborted"
						;;

						*)
						echo "Incorrect response"
					esac
				else
					# On récupère le chemin de l'entité à supprimer (-o donne les résultats sur plusieurs lignes donc on utilise tr pour convertir les retours chariots en "/") sous la forme A/A1 ou A
					toDeletePath=$(echo "$toDelete" | egrep -o "[[:alnum:]]+" | tr '\n' '/' | sed 's/\/$//')
					echo "$toDeletePath"
					# On recupére le nom de l'entité à supprimer
					toDeleteName=$(echo "$toDelete" | egrep -o "[[:alnum:]]+$")
					echo "$toDeleteName"

					# On vérifie que le chemin existe : l'entité est un dossier
					if (echo "$currentArchive" | egrep "^directory $root/$toDeletePath ?$")
					then
						echo "Directory found"
						toDeleteContent=$(echo "$currentArchive" | awk -v directory="$root/$toDeletePath" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
						echo "In this directory :"
						echo "$toDeleteContent"
					# On vérifie que le nom existe et que les permissions ne commencent pas par d : l'entité est un fichier
# BUG : On trouve tous les fichiers avec le même nom; parser le toDeleteContent avec toDeleteContent=$(echo "$currentArchive" | awk -v directory="$root/$toDeletePath" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
					elif (echo "$currentArchive" | egrep "^$toDeleteName [^d]")
					then
						echo "$toDeleteName found"
						# Récupération du contenu du fichier
						toDeleteFile=$(echo "$currentArchive" | egrep "^$toDeleteName [^d]")
						echo "in archive $toDeleteFile"
						# Récupération ligne de début du contenu
						toDeleteBegin=$(echo "$toDeleteFile" | cut -d" " -f4)
						echo "begin at $toDeleteBegin"
						toDeleteBegin=$((toDeleteBegin+bodyBegin-1))
						echo "in archive begins at $toDeleteBegin"
						# Récupération longueur
						toDeleteLength=$(echo "$toDeleteFile" | cut -d" " -f5)
						echo "$toDeleteLength line(s) long"
						# Calcul ligne de fin
						toDeleteEnd=$((toDeleteBegin+toDeleteLength-1))
						echo "end at $toDeleteEnd"
						# Suppression fichier (headder)
						currentArchive=$(echo "$currentArchive" | sed "s/${toDeleteFile}//")
						# Suppression fichier (body)
						currentArchive=$(echo "$currentArchive" | sed "${toDeleteBegin},${toDeleteEnd}s/.*//")
						echo "File deleted"
						echo "$currentArchive"
					else
						echo "No directory or file found"
					fi
				fi
			# Chemin relatif
			else
				echo "Chemin relatif"
				echo "$currentDirectory"
				# Récupérer le nom du dossier ou fichier à supprimer
				if (echo "$toDelete" | egrep -q "/")
				# On souhaite supprimer dans un dossier fils
				then
					echo "Child directory"
					# On récupère le chemin de l'entité à supprimer
					if [ "$currentDirectory" = "/" ]
					then
						toDeletePath=$(echo "$toDelete" | sed -r 's/(\/[^\/]+)$//')
					else
						toDeletePath=$(echo "/$toDelete" | sed -r 's/(\/[^\/]+)$//')
					fi

					echo "path = $toDeletePath"
					# On recupére le nom de l'entité à supprimer
					toDeleteName=$(echo "$toDelete" | egrep -o "[[:alnum:]]+$")
					echo "name of file = $toDeleteName"

					# On regarde si le chemin existe
					if (echo "$currentArchive" | egrep "^directory $root$currentDirectory/?$toDeletePath ?$")
					# On regarde si le fichier/dossier est dans le contenu du dossier	
					then
						echo "$toDeletePath existe dans $currentDirectory"
						
						currentContent=$(echo "$currentArchive" | awk -v directory="$root$currentDirectory$toDeletePath" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
						# On regarde si l'entité existe dans le contenu de ce chemin et est un fichier
						if (echo "$currentContent" | egrep "^$toDeleteName [^d]")
						then
							echo "$toDeleteName est bien un fichier dans $currentDirectory$toDeletePath"
						# On regarde si l'entité existe dans le contenu de ce chemin et est un dossier
						elif (echo "$currentContent" | egrep "^$toDeleteName [d]")
						then
							echo "$toDeleteName est bien un dossier dans $currentDirectory$toDeletePath"
						else
							echo "No file or directory found there"
						fi
					else
						echo "No such path found"
						echo "$root$currentDirectory/?$toDeletePath"
					fi

				# On souhaite supprimer dans le dossier courant
				else
					toDeleteName=$(echo "$toDelete" | egrep -o "[[:alnum:]]+$")
					echo "name of file = $toDeleteName"

					# On liste le contenu du dossier courant
					currentContent=$(echo "$currentArchive" | awk -v directory="$root$currentDirectory" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
					echo "found in $root$currentDirectory with these :"
					echo "$currentContent"

					if [ "$currentDirectory" = "/" ]
					then
						toDeletePath=$(echo "$toDelete" | sed -r 's/(\/[^\/]+)$//')
					else
						# BUG : toDeletePath ne prend pas la valeur lorsque que l'on rajoute le sed
						# FIX : Faire en deux fois de sorte à ne pas se faire piéger par l'expression linéaire qui renvoie tout ce qu'il y a avant le dernier "/" (donc rien si le seul "/" est le premier caractère)
						toDeletePath=$(echo "$toDelete" | sed -r 's/(\/[^\/]+)$//')
						toDeletePath=$(echo "/$toDeletePath")
					fi

					# On vérifie que l'entité existe et est un dossier
					if (echo "$currentContent" | egrep -q "^$toDeleteName d")
					then
						echo "Directory found"
						toDeleteContent=$(echo "$currentArchive" | awk -v directory="$root$currentDirectory$toDeletePath" '$0~directory"$"{flag=1;next}/@/{flag=0}flag')
						echo "$root$currentDirectory$toDeletePath"
						echo "In this directory :"
						echo "$toDeleteContent"
						# BUG : ne liste pas le bon contenu du dossier à supprimer lorsque l'on n'est pas à la racine (liste le dossier courant à la place)
						# FIX : gérer le cas où l'on est à la racine pour la variable $toDeletePath

					# On vérifie que le nom existe dans le dossier courant et que les permissions ne commencent pas par d : l'entité est un fichier
					elif (echo "$currentContent" | egrep "^$toDelete [^d]")
					then
						echo "$toDelete found"
						# Récupération du contenu du fichier
						toDeleteFile=$(echo "$currentArchive" | egrep "^$toDelete [^d]")
						echo "in archive $toDeleteFile"
						# Récupération ligne de début du contenu
						toDeleteBegin=$(echo "$toDeleteFile" | cut -d" " -f4)
						echo "begin at $toDeleteBegin"
						toDeleteBegin=$((toDeleteBegin+bodyBegin-1))
						echo "in archive begins at $toDeleteBegin"
						# Récupération longueur
						toDeleteLength=$(echo "$toDeleteFile" | cut -d" " -f5)
						echo "$toDeleteLength line(s) long"
						# Calcul ligne de fin
						toDeleteEnd=$((toDeleteBegin+toDeleteLength-1))
						echo "end at $toDeleteEnd"
						# Suppression fichier (headder)
						currentArchive=$(echo "$currentArchive" | sed "s/${toDeleteFile}//")
						# Suppression fichier (body)
						currentArchive=$(echo "$currentArchive" | sed "${toDeleteBegin},${toDeleteEnd}s/.*//")
						echo "File deleted"
						echo "$currentArchive"
					else
						echo "No directory or file found"
						
					fi
					
				fi

			fi
			#deleteDirectory $toDelete

		else
			echo "No file to delete"
		fi
		;;

		* )
		echo "unknown command"
	esac
	echo -n "vsh:> "
done
