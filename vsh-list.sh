#!bin/bash

# Les fonctions sont appelées par le script "server"
# Le dossier "script" et le dossier "archives" sont au même niveau d'arborescence
# Il faut donc régulièrement avoir recours à cd ../archives pour intéragir avec son contenu 

function vsh_list() {

	nb_lignes=$(ls -t ../archives/ | wc -l) # le nombre de lignes du ls du dossier archive donne le nombre d'archives
	echo ""
	echo "$nb_lignes archives are currently on HERE" # le HERE sera remplacé par $2 lorsque le fichier sera appelé par server
	echo ""
	echo "The folowing list is sorted by time modified (most recently modified first) :"
	echo ""
	ls -1t ../archives/
	echo ""

}

vsh_list # indispensable actuellement pour tester la fonction (vu qu'elle n'est pas encore appelée par server)
