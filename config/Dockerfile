FROM postgres:18.3

# Mise à jour du système
RUN apt-get update

# Installation des paquets nécessaires au fonctionnement du debugger
RUN apt-get install -y postgresql-18-pldebugger

# Installation des outils de gestion des locales (pour paramétrer la BDD en français)
RUN apt-get -y install locales

# Modification du fichier de configuration utilisé pour la génération des locales
RUN sed -i 's/# fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/g' /etc/locale.gen

# Génération des locales
RUN locale-gen

# Paramétrage des différentes variables d'environnement
ENV LANG=fr_FR.UTF-8
ENV LANGUAGE=fr_FR:e
ENV LC_ALL=fr_FR.UTF-8

# Pour information :
# RUN est une instruction du Dockerfile permettant d'exécuter des commandes
# dans la console lors de la construction de l'image
# 
# à ne pas confondre avec l'instruction CMD
# qui permet d'exécuter des commandes lors du démarrage du conteneur