#!/bin/bash

## actions for project identified by projname
model_action() {
	cmd="$1"
	projname="$2"
	projroot=${DYNDOC_HOME_PROJECT}/${projname}
	case $cmd in
	new ) 
		mkdir -p ${projroot}/{src,share,build,public}
	;;
	add ) # add src element and link it in build
		fname="${projroot}/src/$3"
		bname="`basename ${fname}`"
		dname="`dirname ${fname}`"
		mkdir -p ${dname}
		builddir=${dname/src/build} #replacement of the first src with build
		mkdir -p "${builddir}"
		ln -s ${fname} ${builddir}/${bname}
	;;
	esac
}
	