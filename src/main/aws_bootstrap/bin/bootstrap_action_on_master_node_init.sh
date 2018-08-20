#!/bin/bash

source ../conf/bootstrap_remote.properties
source ./log_utils.sh

function move_bootstrap_artifacts_from_temp_build_path(){

	TEMP_BOOTSTRAP_PATH_ON_MASTER="/tmp/${BOOTSTRAP_DIR_PATH}"

	log " Bootstrapping - Initialization step.. "
	log " TEMP_BOOTSTRAP_PATH_ON_MASTER : ${TEMP_BOOTSTRAP_PATH_ON_MASTER}"
	log " BOOTSTRAP_DIR_PATH: ${BOOTSTRAP_DIR_PATH} "
	
	log "Moving the bootstrap artifacts from ${TEMP_BOOTSTRAP_PATH_ON_MASTER} to ${BOOTSTRAP_DIR_PATH}/${dir_name}"

	for bootstrap_dir_name in "bin" "conf" "lib";do
		rm -rf ${BOOTSTRAP_DIR_PATH}/${bootstrap_dir_name}
		cp -r ${TEMP_BOOTSTRAP_PATH_ON_MASTER}/${bootstrap_dir_name} ${BOOTSTRAP_DIR_PATH}/
	done
}

move_bootstrap_artifacts_from_temp_build_path