#!/bin/bash

## To update 
export BOOT2DOCKER_CMD="boot2docker" #comment this line for linux without boot2docker
export DOCKER_CMD="docker" #or "sudo docker"

#export DOCKER_DYNDOC_CONTAINER="dyndoc" 
#or 
export DOCKER_DYNDOC_CONTAINER="rcqls/dyndoc-docker"

##
. ${DYNDOC_DOCKER_HOME}/etc/init/sh-realpath.sh

ddyn() {
if [ "${DYNDOC_DOCKER_HOME}" ]; then
		if ! [ "${DYNDOC_DOCKER_LIBRARY}" ]; then
			DYNDOC_DOCKER_LIBRARY="${DYNDOC_DOCKER_HOME}/library"
		fi
		if ! [ "${DYNDOC_DOCKER_PROJECT}" ]; then
			DYNDOC_DOCKER_PROJECT="${DYNDOC_DOCKER_HOME}/proj"
		fi
else
	echo "Environment variable DYNDOC_DOCKER_HOME is unset"
	exit
fi

## docker run -v requires absolute path!
if [ "${DYNDOC_DOCKER_LIBRARY}" ]; then
	DYNDOC_DOCKER_LIBRARY=`realpath "${DYNDOC_DOCKER_LIBRARY}"`
else	 
	echo "Environment variable DYNDOC_DOCKER_LIBRARY is unset"
	exit
fi
if [ "${DYNDOC_DOCKER_PROJECT}" ]; then	
	DYNDOC_DOCKER_PROJECT=`realpath "${DYNDOC_DOCKER_PROJECT}"`
else	 
	echo "Environment variable DYNDOC_DOCKER_PROJECT is unset"
	exit
fi

cmd="$1"
case "$cmd" in
help)
	echo "Usage:"
	echo "------"
	echo "*) ddyn env: environment variables"
	echo "*) ddyn start|restart|stop: dyndoc docker container management"
	echo "*) ddyn bash: launch bash shell inside running dyndoc docker container"
	echo "*) ddyn R|irb|gem: R and ruby management"
	echo "*) ddyn <dyn_options> <file>[.dyn]"

;;
env)
	echo "DYNDOC_DOCKER_HOME=$DYNDOC_DOCKER_HOME"
	echo "DYNDOC_DOCKER_LIBRARY=$DYNDOC_DOCKER_LIBRARY"
	echo "DYNDOC_DOCKER_PROJECT=$DYNDOC_DOCKER_PROJECT"
;;
start | restart | stop)
	if [ "${BOOT2DOCKER_CMD}" ] && [ `${BOOT2DOCKER_CMD} status` = "poweroff" ]; then
		${BOOT2DOCKER_CMD} start
	fi
	if [ "${BOOT2DOCKER_CMD}" ] && [ `${BOOT2DOCKER_CMD} status` = "saved" ]; then
		${BOOT2DOCKER_CMD} up
	fi
	if [ "${BOOT2DOCKER_CMD}" ] && [ `${BOOT2DOCKER_CMD} status` = "aborted" ]; then
		${BOOT2DOCKER_CMD} up
	fi
	if [ "$cmd" = "stop" ] || [ "$cmd" = "restart" ]; then
		${DOCKER_CMD} stop dyndoc &>/dev/null; ${DOCKER_CMD} rm dyndoc &>/dev/null
	fi
	if [ "$cmd" = "start" ] || [ "$cmd" = "restart" ]; then
		${DOCKER_CMD} run -d \
		-p 7777:7777 \
		-v ${DYNDOC_DOCKER_PROJECT}:/dyndoc-proj \
		-v ${DYNDOC_DOCKER_LIBRARY}:/dyndoc-library \
		--name dyndoc \
		${DOCKER_DYNDOC_CONTAINER} &>/dev/null
	fi
	echo "docker dyndoc: $cmd server!"
;;
R | irb  | gem | ruby) 
	shift
	${DOCKER_CMD} exec -ti dyndoc $cmd $*
;;
bash)
	${DOCKER_CMD} exec -ti dyndoc /bin/bash
;;
prj)
	shift
	cmd2="$1"
	projname="$2"
	projroot="${DYNDOC_DOCKER_PROJECT}/${projname}"
	etcproj="${DYNDOC_DOCKER_HOME}/etc/proj"
	case "$cmd2" in
	model)
		model="$2"
		if [ -e "${etcproj}/model_${model}.sh" ]; then
			echo "$2" > ${etcproj}/default.model
			echo "default model is now ${model}"
		else
			echo "Warning: $2 is not a proper model"
		fi
	;;
	ls)
		echo `ls ${DYNDOC_DOCKER_PROJECT}`
	;;
	*)
		# The 2 following lines ensures that actions are loaded!
		model="`cat ${etcproj}/default.model`"
		. ${etcproj}/model_${model}.sh
		shift;shift
		##echo "model_action ${cmd2} ${projname} $*"
		model_action ${cmd2} ${projname} $*
	;;
	esac
;;
set | name | root) #shortcut of "ddyn prj cd|set <proj>"
	###DEBUG: echo "_ddyn_prj $cmd $*"
	shift
	_ddyn_prj $cmd $* 
;;
cd )
	shift
	proj="$1"
	_ddyn_prj path "$proj"
	if [ -d $DYNDOC_DOCKER_LAST_PROJECT_PATH ]; then
		cd $DYNDOC_DOCKER_LAST_PROJECT_PATH
	else
		echo "$DYNDOC_DOCKER_LAST_PROJECT_PATH is not a valid directory!"
	fi 
;;
*)
	last="${@: -1}"
	length=$(($#-1))
	dyn_options="${@:1:$length}" #all but last
	##echo "<$last> <$dyn_options>"
	filename=`realpath ${last}`
	filename2=${filename/${DYNDOC_DOCKER_PROJECT}//dyndoc-proj}
	if [ "$filename" = "$filename2" ]; then
		_ddyn_in_room ${filename} $dyn_options
	else
		${DOCKER_CMD} exec dyndoc dyn $dyn_options $filename2
	fi
;;
esac
}

## to compile a dyndoc file not in the project folder!
_ddyn_in_room() {
	filename="$1"
	dyn_options="$2"
	dname=`dirname $filename`
	bname=`basename $filename`
	if ! [ -e "${bname%%.dyn}.dyn" ]; then 
		echo "no file ${bname%%.dyn}.dyn to compile!"
	else
		#no extension for bname and dname at the end with / replaced by - 
		projroot="${DYNDOC_DOCKER_PROJECT}/rooms/${bname%%.*}${dname//\//-}" 
		projname="${projroot}/${bname}"
		# clean room directory if existing and not empty 
		if [ -d ${projroot} ]; then rm -fr ${projroot}/*; fi

		echo "temporary room ${projroot} created!"
		mkdir -p ${projroot}
		cd $dname
		if [ -e ".files" ]; then
			## TODO: consider the contents of .files to filter the files to copy
			cp -r * ${projroot}
		else
			cp "${bname%%.dyn}.dyn" ${projroot}
			if [ -e "${bname%%.dyn}.dyn_cfg" ]; then cp "${bname%%.dyn}.dyn_cfg" ${projroot}; fi
		fi
		echo "current files copied in temporary room ${projroot}!"
		projname2=${projname/${DYNDOC_DOCKER_PROJECT}//dyndoc-proj}
		echo "$projname2 to compile"
		${DOCKER_CMD} exec dyndoc dyn $dyn_options $projname2
		cd $dname
		cp -r ${projroot}/* .
		echo "current files copied from temporary room ${projroot}!"
	fi
}

_ddyn_prj() {
	case "$1" in
	set)
		projname="$2"
		projroot="${DYNDOC_DOCKER_PROJECT}/${projname}"
		if [ -d $projroot ]; then 
			export DYNDOC_DOCKER_CURRENT_PROJECT_NAME="${projname}"
			export DYNDOC_DOCKER_CURRENT_PROJECT_ROOT="${projroot}"
		else
			echo "$projname is not a valid project name!"
		fi
	;;
	name) echo "$DYNDOC_DOCKER_CURRENT_PROJECT_NAME";;
	root) echo "$DYNDOC_DOCKER_CURRENT_PROJECT_ROOT";;
	path) #detect the project and path
		projname="$2";pathname="" #this is the default (only projname provided)
		if [[ $projname =~ (.*):(.*) ]]; then 
			projname=${BASH_REMATCH[1]}
			pathname=${BASH_REMATCH[2]}
		else if [[ $projname =~ / ]]; then 
			pathname=$projname
			if [ "$DYNDOC_DOCKER_CURRENT_PROJECT_NAME" ]; then
				projname=$DYNDOC_DOCKER_CURRENT_PROJECT_NAME
			else
				echo "current project unset (see 'ddyn set')"
				exit
			fi
		fi
		if ! [ "$pathname" = "/*" ]; then pathname="/$pathname"; fi
		projroot="$DYNDOC_DOCKER_PROJECT/$projname"
		export DYNDOC_DOCKER_LAST_PROJECT_NAME="${projname}"
		export DYNDOC_DOCKER_LAST_PROJECT_ROOT="${projroot}"
		if ! [ -d $DYNDOC_DOCKER_LAST_PROJECT_ROOT ]; then
			echo "$DYNDOC_DOCKER_LAST_PROJECT_NAME is not a valid project name!"
			exit
		fi
		export DYNDOC_DOCKER_LAST_PROJECT_PATH="${projroot}${pathname}"
	fi
	;;
	esac
}
