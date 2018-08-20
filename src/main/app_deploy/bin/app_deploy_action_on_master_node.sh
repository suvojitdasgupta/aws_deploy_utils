#!/bin/bash

source ./log_utils.sh
source ./common_utils.sh

function update_job_properties_files_with_correct_hostname(){

	log "Updating coordinator.properties, job.properties files with correct hostname for jobTracker and nameNode properties"
	
	for dir_name in "coordinator" "workflow";do
		if [ -d "${EMR_APP_DEPLOY_DIR_PATH}/${dir_name}" ]; then
			sed -i "s~jobTracker=*.*:8032$~jobTracker=${HOST_NAME}:8032~g" ${EMR_APP_DEPLOY_DIR_PATH}/${dir_name}/*/*.properties
			cmd_status=$?
			if [ $cmd_status -ne 0 ]; then
				echo -e "\n\n Updation of *.properties with jobTracker property failed. Exiting with status $cmd_status \n\n" >&2
				exit $cmd_status
			fi

			sed -i "s~nameNode=hdfs://*.*:8020$~nameNode=hdfs://${HOST_NAME}:8020~g" ${EMR_APP_DEPLOY_DIR_PATH}/${dir_name}/*/*.properties
			cmd_status=$?
			if [ $cmd_status -ne 0 ]; then
				echo -e "\n\n Updation of *.properties with nameNode property failed. Exiting with status $cmd_status \n\n" >&2
				exit $cmd_status
			fi
		fi
	done
	
	log "Updation of *.properties with hostname complete"	
}

function update_job_properties_files_with_correct_environment(){

	log "Updating coordinator.properties, job.properties files with correct ENV property"

	for dir_name in "coordinator" "workflow";do
		if [ -d "${EMR_APP_DEPLOY_DIR_PATH}/${dir_name}" ]; then			
			sed -i "s~^ENV=*.*~ENV=${ENV}~g" ${EMR_APP_DEPLOY_DIR_PATH}/${dir_name}/*/*.properties
			cmd_status=$?
			if [ $cmd_status -ne 0 ]; then
				echo -e "\n\n Updation of *.properties with ENV property failed. Exiting with status $cmd_status \n\n" >&2
				exit $cmd_status
			fi
		fi
	done

	log "Updation of *.properties with ENV property complete"	
}

function setup_app_data_in_hdfs(){
	
	local install_timestamp="$(date +"%Y%m%d_%H_%M_%S")"
	log "Creating dir on hdfs for EMR_APP_HDFS_DIR_PATH :${EMR_APP_HDFS_DIR_PATH}"
	hadoop fs -mkdir -p ${EMR_APP_HDFS_DIR_PATH}
	
	log "Copying the app_deploy resources to the EMR_APP_HDFS_DIR_PATH"
	for dir_name in "coordinator" "workflow" "dbc" "lib" "pig" "shell" "config";do
		if [ -d "${EMR_APP_DEPLOY_DIR_PATH}/${dir_name}" ]; then
   			hadoop fs -rm -r ${EMR_APP_HDFS_DIR_PATH}/${dir_name}
   			hadoop fs -copyFromLocal -f ${EMR_APP_DEPLOY_DIR_PATH}/${dir_name} ${EMR_APP_HDFS_DIR_PATH}/${dir_name}
		fi
	done

	log "Creating the app base output dir on hdfs"
	hadoop fs -mkdir -p ${EMR_APP_HDFS_DIR_PATH}/output
}

function validate_workflow_xmls(){

	if [ -d "${EMR_APP_DEPLOY_DIR_PATH}/workflow" ]; then
		export OOZIE_URL="http://localhost:11000/oozie"
		log "Validating the workflow.xml related to all workflows"
		for workflow_dir_name in ${EMR_APP_DEPLOY_DIR_PATH}/workflow/*;do	
			log "validating workflow - ${workflow_dir_name}"
			oozie validate ${workflow_dir_name}/workflow.xml
			cmd_status=$?
			if [ $cmd_status -ne 0 ]; then
				echo -e "\n\n Invalid workflow.xml . Exiting with status $cmd_status \n\n" >&2
				exit $cmd_status
			fi
		done
		log "Validation of workflow.xml related to all workflows - complete"
	fi
}

function execute_app_deploy_action(){
	ensure_deploy_app_variables_are_set || exit 1
	log "Executing app_deploy actions .."	
	log " HOST_NAME: ${HOST_NAME} "
	log " EMR_APP_DEPLOY_DIR_PATH: ${EMR_APP_DEPLOY_DIR_PATH} "
		
	update_job_properties_files_with_correct_hostname
	update_job_properties_files_with_correct_environment
	setup_app_data_in_hdfs
	validate_workflow_xmls
	
	log "app_deploy complete on the remote master node"
}

HOST_NAME=$1
execute_app_deploy_action

