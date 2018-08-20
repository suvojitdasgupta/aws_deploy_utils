#!/bin/bash

source ../conf/bootstrap_remote.properties
source ./log_utils.sh

function execute_command(){
	local cmd=$1
	echo -e "\nExecuting, ${cmd} \n"
	eval "${cmd}"
}

function setup_hdfs_for_new_user(){

	local username=$1
	local instance_json_path="/mnt/var/lib/info/instance.json"
	if [ -f ${instance_json_path} -a -s ${instance_json_path} ] ; then
		local is_master=$(echo `jq '.isMaster' ${instance_json_path}`)
		if [ "${is_master}" == "true" ] ; then
			log "Node is the master."
			execute_command "hadoop fs -mkdir /user/${username}"
			execute_command "hadoop fs -chown -R ${username}:${username} /user/${username}"
			execute_command "hdfs dfs -setfacl -R -m user:${username}:r-x /"
		else
			log "Node is not the master. Skipping hdfs setup for the new user .."
		fi
	else
		log " File ${instance_json_path} not present. Skipping hdfs setup for the new user .."
	fi	
}

function setup_hdfs_for_credential_management(){

	local base_user=$1
	local user_to_exclude=$2
	local environments=$3
	
	local base_hdfs_dir="/user/${base_user}/credentials/"
	
	for environment in $(echo ${environments} | sed "s/,/ /g")
	do
		local base_hdfs_dir="/user/${base_user}/${environment}/credentials/"
		local credential_provider_s3_location="s3n://obi-brr-config-${environment}/db/common/db.jceks"
		local credential_provider_hdfs_location="${base_hdfs_dir}/db.jceks"

		execute_command "hadoop fs -mkdir -p ${base_hdfs_dir}"
		execute_command "hdfs dfs -setfacl -R -m user:${user_to_exclude}:--- ${base_hdfs_dir}"
		hadoop fs -test -e "${credential_provider_s3_location}"
		if [ $? -eq 0 ];
		then
			log " Environment=${environment} - Removing the (if available) credential file on HDFS"
			execute_command "hadoop fs -rm ${credential_provider_hdfs_location}"			
			log " Environment=${environment} - Copying the available credential file from S3 to the HDFS"
			execute_command "hadoop fs -cp ${credential_provider_s3_location} ${credential_provider_hdfs_location}"
		fi
	done

}

function setup_oozie_support_for_s3(){	
	execute_command "sudo cp -v /usr/share/aws/emr/emrfs/lib/*.jar /var/lib/oozie/"
	execute_command "sudo stop oozie"
	echo "Sleeping for 10 secs " && sleep 10 && echo "Completed sleep"
	execute_command "sudo start oozie"
}

function execute_bootstrap_action(){

	log "Executing Bootstraping actions .."

	log "Installing Extjs lib under /var/lib/oozie"

	sudo rm -r /var/lib/oozie/ext-2.2
	sudo unzip -qq ${BOOTSTRAP_DIR_PATH}/lib/ext-2.2.zip -d /var/lib/oozie
	
	# Please see https://forums.aws.amazon.com/thread.jspa?threadID=244691 for details.
	log "Installing jasper-compiler-jdt lib under /usr/lib/oozie/lib/"
	
	sudo rm /usr/lib/oozie/lib/jasper-compiler-jdt-5.5.23.jar
	sudo cp ${BOOTSTRAP_DIR_PATH}/lib/jasper-compiler-jdt-5.5.23.jar /usr/lib/oozie/lib/
	
	execute_command "rm ~/.oozie-auth-token"
	local oozie_share_lib_hdfs_base_path="$(echo `oozie admin -sharelibupdate |grep sharelibDirNew|sed 's/[[:space:]]\+//g'|awk -F'=' '{print $2}'`)"
	if [ -z "$oozie_share_lib_hdfs_base_path" ];then
		echo -e "\n\n Could not identify latest share-lib dir ! oozie_share_lib_hdfs_base_path=${oozie_share_lib_hdfs_base_path} . Exiting.."
		exit 1
	fi
	local oozie_share_lib_sqoop_hdfs_path="${oozie_share_lib_hdfs_base_path}/sqoop"
	
	log "Copying sqoop related jdbc jars to hdfs path ${oozie_share_lib_sqoop_hdfs_path}/ .."

	for jar_name in "jtds-1.3.1.jar" "mysql-connector-java-5.1.37-bin.jar" "ojdbc6.jar";do

		log " Deleting older version (if any) of the ${jar_name} from hdfs"
		hadoop fs -rm ${oozie_share_lib_sqoop_hdfs_path}/${jar_name}
		log " Copying the newer version of the ${jar_name} from hdfs"
		hadoop fs -put ${BOOTSTRAP_DIR_PATH}/lib/${jar_name} ${oozie_share_lib_sqoop_hdfs_path}/

	done

	log "Updating the oozie sharelib to reflect the contents of the ${oozie_share_lib_sqoop_hdfs_path} "

	execute_command "rm ~/.oozie-auth-token"
	execute_command "oozie admin -sharelibupdate"
	
	log "Setting up Oozie to support s3 filesystem based on EMRFS"

	setup_oozie_support_for_s3
	
	log "Bootstraping complete on the remote master node"
}

read_write_user="hadoop"
read_only_user="obi-user"
environments="dev,qa,prod,stage"


echo -e "\n\n======================== Custom Bootstrapping - Begin ========================\n\n"

log " read_write_user : ${read_write_user}"
log " read_only_user : ${read_only_user}"
log " environments : ${environments}"
log " BOOTSTRAP_DIR_PATH: ${BOOTSTRAP_DIR_PATH} "


echo -e "\n\n-------------------- Step1 : Setting up hdfs for read_only_user : ${read_only_user} --------------------\n\n"
setup_hdfs_for_new_user "${read_only_user}"

echo -e "\n\n-------------------- Step2 : Setting up hdfs for credential management read_write_user: ${read_write_user} , read_only_user: ${read_only_user} --------------------\n\n"
setup_hdfs_for_credential_management "${read_write_user}" "${read_only_user}" "${environments}"

echo -e "\n\n-------------------- Step3 : Execute bootstrap actions --------------------------------------------------\n\n"
execute_bootstrap_action

echo -e "\n\n======================== Custom Bootstrapping - Complete ========================\n\n"