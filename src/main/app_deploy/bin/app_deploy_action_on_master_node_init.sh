#!/bin/bash

source ./log_utils.sh
source ./common_utils.sh


function move_artifacts_from_temp_build_path(){
	ensure_deploy_app_variables_are_set || exit 1
	TEMP_BUILD_DEPLOY_PATH_ON_MASTER="/tmp/${EMR_APP_DEPLOY_DIR_PATH}"
	
	log " App-Deploy - Initialization step.. "
	
	log " TEMP_BUILD_DEPLOY_PATH_ON_MASTER : ${TEMP_BUILD_DEPLOY_PATH_ON_MASTER}"
	log " EMR_APP_DEPLOY_DIR_PATH: ${EMR_APP_DEPLOY_DIR_PATH} "

	log "Moving the new deploy and build artifacts from ${TEMP_BUILD_DEPLOY_PATH_ON_MASTER} to ${EMR_APP_DEPLOY_DIR_PATH}/${dir_name}"

	for build_dir_name in ${EMR_APP_DEPLOY_DIR_PATH}/*;do
		local dir_name=$(basename `echo ${build_dir_name}`)
		if [ "$dir_name" != "logs" ];
		then
			rm -rf ${EMR_APP_DEPLOY_DIR_PATH}/${dir_name}
		fi
	done
	
	for build_dir_name in ${TEMP_BUILD_DEPLOY_PATH_ON_MASTER}/*;do
		local dir_name=$(basename `echo ${build_dir_name}`)
		cp -r ${build_dir_name} ${EMR_APP_DEPLOY_DIR_PATH}/
	done
}

move_artifacts_from_temp_build_path
