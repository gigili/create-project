#!/bin/bash

#clear

PROJECT_NAME="$1"                       # first argument passed to the script is the name of the project
PROJECT_PATH="${2:-$PWD}/$PROJECT_NAME" # use current dir for the path

# Check to make sure the project name is not empty
if [[ -z "$PROJECT_NAME" ]]; then
	log "Project name can't be empty" "error"
	abort
fi

#MySQL Login info
MYSQL_USER="root"
MYSQL_PASSWORD="toor"

GIT_REPO="$3" # the third argument passed to the script should be a git repo url

USE_SILENT=false

setup_flags() {
	while [[ $# -gt 0 ]]; do
		opt="$1"

		shift

		current_arg="$1"

		if [[ "$current_arg" =~ ^-{1,2}.* ]]; then
			log "You may have left an argument blank. Double check your command." "warning"
		fi

		case "$opt" in
		"-h" | "--help")
			echo "This should display help for screen for this script "
			;;
		"-p" | "--project")
			PROJECT_NAME="$1"

			if [[ -n "$PROJECT_PATH" ]]; then
				PROJECT_PATH="$PWD/$PROJECT_NAME"
			fi
			shift
			;;
		"-pp" | "--path")
			PROJECT_PATH="$1/$PROJECT_NAME"
			shift
			;;
		"-g" | "--git")
			echo "USE GIT FOR THIS PROJECT"
				GIT_REPO="$1"
			shift
			;;
		"-q" | "--quite")
			USE_SILENT=true
			shift
			;;
		*) shift ;;
		esac
	done
}

log() {
	color=""
	prefix="[INFO]"
	lvl=$2

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

	if [ "$USE_GIT" = true ]; then
		git init "$PROJECT_PATH" >/dev/null 2>&1
		log "Initialized git repo in $PROJECT_PATH" "log"

		if [[ -n "$GIT_REPO" ]]; then
			git remote add origin "$GIT_REPO"
			log "Added repository origin url" "info"
		fi
	fi

	create_database

	open_editor
}

create_database() {
	mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" <<EOFMYSQL
				DROP DATABASE IF EXISTS \`$PROJECT_NAME\`;
				CREATE DATABASE IF NOT EXISTS \`$PROJECT_NAME\`;
EOFMYSQL

	log "Created new MySQL database: $PROJECT_NAME" "info"
}

open_editor() {
	# phpstorm "$PROJECT_PATH"
	#$("$EDTIOR $PROJECT_PATH")
	subl $PROJECT_PATH
}

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
