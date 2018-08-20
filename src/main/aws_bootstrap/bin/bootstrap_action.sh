#!/bin/bash

source ${AWS_DEPLOY_UTIL_PATH}/src/main/aws_bootstrap/bin/log_utils.sh
source ${AWS_DEPLOY_UTIL_PATH}/src/main/aws_bootstrap/conf/bootstrap_remote.properties
source ${AWS_DEPLOY_UTIL_PATH}/src/main/aws_cluster_creation/bin/aws_cluster_info_utils.sh

function bootstrap(){
	
	TEMP_BOOTSTRAP_PATH_ON_MASTER="/tmp/${BOOTSTRAP_DIR_PATH}"
	RUNTIME_STAMP="$(date +"%Y%m%d_%H_%M_%S")"
	
	log "\n\n --- Creating bootstrap install dir on remote master host from the localhost ---- \n"
	log " HOST_NAME : ${HOST_NAME} , BOOTSTRAP_DIR_PATH : ${BOOTSTRAP_DIR_PATH}, TEMP_BOOTSTRAP_PATH_ON_MASTER : ${TEMP_BOOTSTRAP_PATH_ON_MASTER}"

	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no hadoop@${HOST_NAME} bash -c "'
	mkdir -p ${BOOTSTRAP_DIR_PATH}/logs 2>&1
	rm -rf ${TEMP_BOOTSTRAP_PATH_ON_MASTER}  2>&1 	|tee -a ${BOOTSTRAP_DIR_PATH}/logs/bootstrap_action_${RUNTIME_STAMP}.log
	mkdir -p ${TEMP_BOOTSTRAP_PATH_ON_MASTER}  2>&1 |tee -a ${BOOTSTRAP_DIR_PATH}/logs/bootstrap_action_${RUNTIME_STAMP}.log
	
	'"

	log "\n\n --- SCPing the bootstrap resources to the master node ---- \n"

	scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r ${AWS_DEPLOY_UTIL_PATH}/src/main/aws_bootstrap/{bin,conf,lib} hadoop@${HOST_NAME}:${TEMP_BOOTSTRAP_PATH_ON_MASTER}/

	log "\n\n --- Executing bootstrap_action_on_master_node_init.sh ---- \n"
	ssh  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no hadoop@${HOST_NAME} "cd ${TEMP_BOOTSTRAP_PATH_ON_MASTER}/bin && ./bootstrap_action_on_master_node_init.sh 2>&1 |tee -a ${BOOTSTRAP_DIR_PATH}/logs/bootstrap_action_${RUNTIME_STAMP}.log" || exit 1

	log "\n\n --- Executing bootstrap_action_on_master_node.sh ---- \n"	
	ssh  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no hadoop@${HOST_NAME} "cd ${BOOTSTRAP_DIR_PATH}/bin && ./bootstrap_action_on_master_node.sh 2>&1 |tee -a ${BOOTSTRAP_DIR_PATH}/logs/bootstrap_action_${RUNTIME_STAMP}.log" || exit 1
	
	log "\n\n --- Bootstrapping complete on master node ---- \n"

}

if [ -z "$EMR_CLUSTER_NAME" ];then
	echo -e "\n\n Deploy app variable(s) not set ! EMR_CLUSTER_NAME=${EMR_CLUSTER_NAME} . Exiting.."
	exit 1
fi

export HOST_NAME="$(get_emr_masternode_private_dns)"

if [ -z "$HOST_NAME" ];then
	echo -e "\n\n Deploy app variable(s) not set ! HOST_NAME=${HOST_NAME} . Exiting.."
	exit 1
fi

bootstrap