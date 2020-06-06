#!/bin/bash

# 			GNU GENERAL PUBLIC LICENSE
#			  Version 3, 29 June 2007
#
# Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
# Everyone is permitted to copy and distribute verbatim copies
# of this license document, but changing it is not allowed.

#title           :create-project
#description     :This script will create all the folders, the database and open the specified code editor when starting a new project
#author		 	 :Igor Ilić
#website		 :https://igorilic.net
#twitter		 :https://twitter.com/Gac_BL
#date            :06-06-2020
#version         :0.1
#usage		     :create-project.sh <project-name> [-h | -p | -g | -e | -l | -q]

slugify() {
	slug=$(echo "$1" | iconv -t ascii//TRANSLIT | sed -r s/[~^]+//g | sed -r s/[^a-zA-Z0-9]+/_/g | sed -r s/^-+\|-+\$//g | tr "[:upper:]" "[:lower:]")
	echo "$slug"
}

#clear

#MySQL Login info
MYSQL_USER="root"
MYSQL_PASSWORD="toor"
VIRTUAL_HOST_PATH="/etc/httpd/conf/extra/sites-enabled"
RESTART_SERVICE="systemctl restart httpd"

PROJECT_NAME="$1"                          # first argument passed to the script is the name of the project
SL_PROJECT_NAME=$(slugify "$PROJECT_NAME") # url friendly version of the project name
PROJECT_PATH="${2:-$PWD}/$SL_PROJECT_NAME" # use current dir for the path

GIT_REPO=""
CODE_EDITOR="phpstorm" # change the default value to your preference
PROJECT_LANG=""
USE_SILENT=false
VHOST_URL=""

# Check to make sure the project name is not empty
if [[ -z "$PROJECT_NAME" ]]; then
	log "Project name can't be empty" "error"
	abort
fi

setup_flags() {
	while [[ $# -gt 0 ]]; do
		opt="$1"

		case "$opt" in
		"-h" | "--help")
			echo "Usage: create-project.sh <project-name> [-h | -p | -g | -e | -l | -q]"
			echo "Options:"
			echo "-h, --help   			Displays this help text"
			echo "-p, --path   			Sets the path of where the project should be created"
			echo "-g, --git    			Sets the git repository url"
			echo "-q, --quite			Runs the script without any output or prompt to the users except errors"
			echo "-e, --editor			Sets the code editor to be opened once the script is done"
			echo "-l, -lang, --language		Sets the programming language used for the project and runs language specific steps to initialize everything"

			exit 0
			;;
		"-p" | "--path")
			shift
			PROJECT_PATH="$1"

			if [[ -n "$PROJECT_PATH" ]]; then
				PROJECT_PATH="$PROJECT_PATH/$SL_PROJECT_NAME"
			else
				PROJECT_PATH="$PWD/$SL_PROJECT_NAME"
			fi
			shift
			;;
		"-g" | "--git")
			shift
			GIT_REPO="$1"
			shift
			;;
		"-q" | "--quite")
			shift
			USE_SILENT=true
			shift
			;;
		"-e" | "--editor")
			shift
			CODE_EDITOR="$1"
			shift
			;;
		"-l" | "-lang" | "--language")
			shift
			PROJECT_LANG="$1"
			shift
			;;
		*) shift ;;
		esac
	done
}

log() {
	color=""
	prefix="[INFO]"
	lvl=${2:-"info"}

	if [[ "$lvl" == "success" ]]; then
		color="\e[92m"
		prefix="[SUCCESS]"
	elif [[ "$lvl" == "warning" ]]; then
		color="\e[93m"
		prefix="[WARNING]"
	elif [[ "$lvl" == "error" ]]; then
		color="\e[91m"
		prefix="[ERROR]"
	else
		color="\e[37m"
	fi

	if [ "$USE_SILENT" = true ] && [ "$lvl" != "error" ]; then
		return
	fi

	echo -e "$color$prefix $1 \e[0m"
}

ask_for_confirmation() {

	if [ "$USE_SILENT" = true ]; then
		true
		return
	fi

	echo -n -e "\e[37mConfirm [Y/n]:\e[0m "
	read -n 1 -r
	echo

	if [[ -z "$REPLY" ]]; then
		REPLY="y"
	fi

	case "$REPLY" in
	y | Y) true return ;;
	n | N) false return ;;
	*) ask_for_confirmation ;;
	esac

}

abort() {
	log "Aborting ..." "error"
	exit 0
}

create_new_project() {
	log "Creating \e[31m$PROJECT_NAME\e[0m \e[37mat\e[0m \e[31m$PROJECT_PATH \e[0m" "log"

	if [[ $(mkdir -p "$PROJECT_PATH") ]]; then
		log "Created project folder" "success"
	fi

	log "Changing working directory to $PROJECT_PATH" "info"
	cd "$PROJECT_PATH" || return

	if [[ $(echo "# $PROJECT_NAME" | cat >>"$PROJECT_PATH/README.md") ]]; then
		log "Created README.md" "success"
	fi

	# make sure git exists before using it
	if [[ -z $(type -p "git") ]]; then
		git init "$PROJECT_PATH" >/dev/null 2>&1
		log "Initialized empty git repo in $PROJECT_PATH" "log"

		if [[ -n "$GIT_REPO" ]]; then
			git remote add origin "$GIT_REPO"
			log "Added repository origin url: $GIT_REPO" "info"
		fi
	fi

	create_database                # Create database for the project
	setup_virtual_host             # Setup virtual host route for the project
	setup_language_specific_config # Initialize specific default folders based on the selected project language
	open_editor                    # Open the specified code editor or fallback to the default one
}

create_database() {
	if [[ -z $(type -p "mysql") ]]; then
		log "MySQL is not installed. Skipping database creation" "warning"
		return
	fi

	mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" <<EOFMYSQL
		DROP DATABASE IF EXISTS \`$SL_PROJECT_NAME\`;
		CREATE DATABASE IF NOT EXISTS \`$SL_PROJECT_NAME\`;
EOFMYSQL

	log "Created new MySQL database: $SL_PROJECT_NAME" "success"
}

setup_language_specific_config() {
	if [[ -z "$PROJECT_LANG" ]]; then
		PROJECT_LANG="php"
	fi

	case "$PROJECT_LANG" in
	php)
		if [[ -z $(type -p "composer") ]]; then
			log "Composer is not installed. Skipping setup." "warning"
			return
		fi

		composer init "$PROJECT_PATH" --name="$PROJECT_NAME" --type="project" --homepage="$VHOST_URL" --repository="$GIT_REPO"
		;;
	node)
		if [[ -z $(type -p "node") ]]; then
			log "Node is not installed. Skipping setup." "warning"
			return
		fi

		npm init "$PROJECT_PATH" --yes
		;;
	*) return ;;
	esac
}

open_editor() {
	if [[ -z "$CODE_EDITOR" ]]; then
		CODE_EDITOR="phpstorm"
	fi

	if [[ -z $(type -p "$CODE_EDITOR") ]]; then
		log "Unable to find the executable for the code editor: $CODE_EDITOR" "error"
		return
	fi

	log "Running $CODE_EDITOR $PROJECT_PATH" "info"
	"$CODE_EDITOR" "$PROJECT_PATH" >/dev/null 2>&1

}

setup_virtual_host() {
	log "Setup new virtual host for project $PROJECT_NAME?" "info"

	if ! ask_for_confirmation; then
		log "Skipping virtual host creation" "info"
		return
	fi

	log "Creating new virtual host entry for $PROJECT_NAME" "info"

	echo -n -e "\e[37mProject url:\e[0m "
	read -r
	echo

	VHOST_URL="$REPLY"

	VH_FILE="<VirtualHost *:80>
		ServerAdmin admin@example.com
		DocumentRoot \"$PROJECT_PATH\"
		ServerName \"$VHOST_URL\"
		ServerAlias \"www.$VHOST_URL\"
		ErrorLog \"$PROJECT_PATH/logs/error.log\"
		CustomLog \"$PROJECT_PATH/logs/access.log\" common
		<Directory \"$PROJECT_PATH\">
			AllowOverride All
		</Directory>
	</VirtualHost>"

	if [[ -d "$VIRTUAL_HOST_PATH" ]]; then
		log "Invalid path to the virtual hosts config folder." "error"
		return
	fi

	if [[ $(echo "$VH_FILE" | sudo tee -a "$VIRTUAL_HOST_PATH/$SL_PROJECT_NAME.conf") ]]; then
		log "Virtual host for $PROJECT_NAME created successfully" "success"

		if [[ $(echo "127.0.0.1 $VHOST_URL" | sudo tee -a "/etc/hosts") ]] && [[ $(echo "127.0.0.1 www.$VHOST_URL" | sudo tee -a "/etc/hosts") ]]; then
			log "Added $VHOST_URL to the hosts file" "success"
		fi

		log "Restarting apache" "info"

		if [[ $(sudo "$RESTART_SERVICE" >/dev/null 2>&1) ]]; then
			log "Apache service restarted" "success"
		else
			log "Unable to restart apache" "warning"
		fi
	fi
}

if [[ -z "$PROJECT_PATH" ]] || [[ ! $(readlink -f "$PROJECT_PATH" >/dev/null 2>&1) ]]; then
	PROJECT_PATH="$PWD/$SL_PROJECT_NAME"
fi

setup_flags "$@"

log "Creating project: $PROJECT_NAME" "info"
log "Create project in directory: $PROJECT_PATH ?" "info"

if ask_for_confirmation; then

	if [[ -d "$PROJECT_PATH" ]]; then
		log "Path already exists" "warning"
		log "\e[91mRemove old files?\e[0m" "warning"
		if ask_for_confirmation; then
			rm -rf "$PROJECT_PATH"
		else
			abort
		fi
	fi

	create_new_project

else
	abort
fi

echo "writing"
