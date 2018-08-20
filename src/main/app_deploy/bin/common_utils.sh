
function ensure_deploy_app_variables_are_set(){

	if [ -z "$ENV" -o -z "$EMR_APP_HDFS_DIR_PATH" -o -z "$EMR_APP_DEPLOY_DIR_PATH" -o -z "$HOST_NAME" ];then
		echo -e "\n\nDeploy app variable(s) not set ! ENV=${ENV} , EMR_APP_HDFS_DIR_PATH=${EMR_APP_HDFS_DIR_PATH} , EMR_APP_DEPLOY_DIR_PATH=${EMR_APP_DEPLOY_DIR_PATH} , HOST_NAME=${HOST_NAME} . Exiting.."
		exit 1
	fi
}