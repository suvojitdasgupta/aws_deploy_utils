#!/bin/bash

source ${AWS_DEPLOY_UTIL_PATH}/src/main/app_deploy/bin/log_utils.sh
source ${AWS_DEPLOY_UTIL_PATH}/src/main/app_deploy/bin/common_utils.sh
source ${AWS_DEPLOY_UTIL_PATH}/src/main/aws_cluster_creation/bin/aws_cluster_info_utils.sh

function app_deploy(){	
	ensure_deploy_app_variables_are_set || exit 1

	TEMP_BUILD_DEPLOY_PATH_ON_MASTER="/tmp/${EMR_APP_DEPLOY_DIR_PATH}"
	RUNTIME_STAMP="$(date +"%Y%m%d_%H_%M_%S")"
	
	log "\n\n ---- Creating app_deploy temp dir on remote master host from the localhost ---- \n"
	log " HOST_NAME : ${HOST_NAME} , EMR_APP_DEPLOY_DIR_PATH : ${EMR_APP_DEPLOY_DIR_PATH}, TEMP_BUILD_DEPLOY_PATH_ON_MASTER : ${TEMP_BUILD_DEPLOY_PATH_ON_MASTER}"
	
	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no hadoop@${HOST_NAME} bash -c "'
		mkdir -p ${EMR_APP_DEPLOY_DIR_PATH}/logs  2>&1
		rm -rf ${TEMP_BUILD_DEPLOY_PATH_ON_MASTER}  2>&1 	|tee -a ${EMR_APP_DEPLOY_DIR_PATH}/logs/app_deploy_action_$RUNTIME_STAMP.log
		mkdir -p ${TEMP_BUILD_DEPLOY_PATH_ON_MASTER}  2>&1 	|tee -a ${EMR_APP_DEPLOY_DIR_PATH}/logs/app_deploy_action_$RUNTIME_STAMP.log
	'"

	log "\n\n ---- SCPing the app_deploy resources to the master node ---- \n"
	
	scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r ${AWS_DEPLOY_UTIL_PATH}/src/main/app_deploy/bin hadoop@${HOST_NAME}:${TEMP_BUILD_DEPLOY_PATH_ON_MASTER}/

	log "\n\n ---- SCPing the app_build resources to the master node ---- \n"

	scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r ${APP_BUILD_PATH}/* hadoop@${HOST_NAME}:${TEMP_BUILD_DEPLOY_PATH_ON_MASTER}
		
	log "\n\n ---- Executing app_deploy_action_on_master_node_init.sh ---- \n"
	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no hadoop@${HOST_NAME} "export ENV=${ENV} && export EMR_APP_DEPLOY_DIR_PATH=${EMR_APP_DEPLOY_DIR_PATH} && export EMR_APP_HDFS_DIR_PATH=${EMR_APP_HDFS_DIR_PATH} && export HOST_NAME=${HOST_NAME} && cd ${TEMP_BUILD_DEPLOY_PATH_ON_MASTER}/bin && ./app_deploy_action_on_master_node_init.sh 2>&1 |tee -a ${EMR_APP_DEPLOY_DIR_PATH}/logs/app_deploy_action_$RUNTIME_STAMP.log" || exit 1

	log "\n\n ---- Executing app_deploy_action_on_master_node.sh ---- \n"
	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no hadoop@${HOST_NAME} "export ENV=${ENV} && export EMR_APP_DEPLOY_DIR_PATH=${EMR_APP_DEPLOY_DIR_PATH} && export EMR_APP_HDFS_DIR_PATH=${EMR_APP_HDFS_DIR_PATH} && export HOST_NAME=${HOST_NAME} && cd ${EMR_APP_DEPLOY_DIR_PATH}/bin && ./app_deploy_action_on_master_node.sh ${HOST_NAME} 2>&1 |tee -a ${EMR_APP_DEPLOY_DIR_PATH}/logs/app_deploy_action_$RUNTIME_STAMP.log" || exit 1


	log "\n\n ---- App deployment complete on master node ---- \n"

}

if [ -z "$EMR_CLUSTER_NAME" ];then
	echo -e "\n\n Deploy app variable(s) not set ! EMR_CLUSTER_NAME=${EMR_CLUSTER_NAME} . Exiting.."
	exit 1
fi

export HOST_NAME="$(get_emr_masternode_private_dns)"

app_deploy