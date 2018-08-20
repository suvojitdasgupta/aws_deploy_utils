#!/bin/bash

source ${AWS_DEPLOY_UTIL_PATH}/src/main/aws_cluster_creation/conf/emr_cluster_common.properties
source ${AWS_DEPLOY_UTIL_PATH}/src/main/aws_cluster_creation/conf/${ENV}/emr_cluster.properties
source ${AWS_DEPLOY_UTIL_PATH}/src/main/aws_cluster_creation/bin/aws_cluster_info_utils.sh

function get_formatted_applications_name(){
	
	local application_names=""
	local default_application_name="Not_Defined"
	
	for application in $(echo "${EMR_APPLICATION_NAMES}"|tr "," " ");do		
		application_names="$application_names Name=$application"	
	done
	
	if [ -z application_names ];
	then
		echo "$default_application_name"
	else
		echo "$(echo "$application_names"| sed s/\ //)"
	fi	
}

function wait_until_cluster_creation_to_complete(){
	local cluster_name=$1
	local query_param=$(echo "Clusters[?Name==\`$cluster_name\`].[Id]")
			
	local cluster_id=$(get_cluster_id "$query_param" True)

	log "Query_param:$query_param"	
	log "Cluster_id related to query param:$cluster_id"
	
	log "Waiting for the EMR cluster creation to complete.." 
	aws emr wait cluster-running --cluster-id "$cluster_id" 2>/dev/null
	log "Wait complete." 
}

function update_host_properties_file_with_master_node_private_dns(){

	local cluster_name=$1
	local query_param=$(echo "Clusters[?Name==\`$cluster_name\`].[Id]")
	local cluster_id=$(get_cluster_id "$query_param" True)
	local master_node_private_dns="$(echo `aws emr list-instances --cluster-id "$cluster_id" --instance-group-types "MASTER"|jq -r '.Instances|.[0].PrivateDnsName'`)"
	
	log "master_node_private_dns : ${master_node_private_dns}"
	
}

function create_aws_cluster(){

	local wait_until_cluster_creation_suceeds=$1
	local cluster_name=${EMR_CLUSTER_NAME}	
	local applications_name=$(get_formatted_applications_name)
	local emr_log_uri="s3n://obi-brr-hadoop-porting-${ENV}/cluster-logs/"
	
	local query_param=$(echo "Clusters[?Name==\`$cluster_name\`].[Id]")
	local number_of_clusters_matching_id=$(get_number_of_clusters_matching_criteria "$query_param" "True")
	
	log "Query_param:$query_param"
	log "Number_of_active emr clusters matching cluster name - $cluster_name is $number_of_clusters_matching_id ."
	
	if [ $number_of_clusters_matching_id -gt 0 ];
	then
		failed "Multiple active clusters exist with name $cluster_name. Exiting create operation !"
	elif [ $number_of_clusters_matching_id -eq 0 ]
	then		
		log "Creating EMR cluster .. with applications,$applications_name"
		aws emr create-cluster \
		--auto-scaling-role "EMR_AutoScaling_DefaultRole" \
		--termination-protected \
		--applications ${applications_name} \
		--bootstrap-actions file://${AWS_DEPLOY_UTIL_PATH}/src/main/aws_cluster_creation/conf/${ENV}/custom_bootstrap_for_additional_installs.json \
		--tags "Name=$cluster_name" \
		--ec2-attributes file://${AWS_DEPLOY_UTIL_PATH}/src/main/aws_cluster_creation/conf/${ENV}/ec2_attributes.json \
		--service-role "${EMR_SERVICE_ROLE}" \
		--enable-debugging \
		--release-label "${EMR_RELEASE_LABEL}" \
		--log-uri "${emr_log_uri}" \
		--name "$cluster_name" \
		--instance-groups "`cat ${AWS_DEPLOY_UTIL_PATH}/src/main/aws_cluster_creation/conf/${ENV}/instance_groups.json`" \
		--configurations "`cat ${AWS_DEPLOY_UTIL_PATH}/src/main/aws_cluster_creation/conf/configurations.json`" \
		--scale-down-behavior "TERMINATE_AT_TASK_COMPLETION" \
		--region "${EMR_REGION}" \
		--custom-ami-id "${SECURE_AMI_ID}" \
		--security-configuration "${EMR_SECURITY_CONF}"

		if [ "$wait_until_cluster_creation_suceeds" == "True" ];
		then
			wait_until_cluster_creation_to_complete "$cluster_name"
			update_host_properties_file_with_master_node_private_dns "$cluster_name"
			log "EMR cluster creation complete. Sleeping for 10 secs .."
			sleep 10 && log "Completed sleep."
		else
			log "EMR cluster creation command executed."
		fi
	fi

	
	

}

function terminate_aws_cluster(){

	local cluster_name=${EMR_CLUSTER_NAME}
	local query_param=$(echo "Clusters[?Name==\`$cluster_name\`].[Id]")
	local cluster_id=$(get_cluster_id "$query_param" True)
	local number_of_clusters_matching_id=$(get_number_of_clusters_matching_criteria "$query_param" "True")
	
	log "Query_param:$query_param"
	log "Number_of_active emr clusters matching cluster name - $cluster_name is $number_of_clusters_matching_id ."
	
	if [ $number_of_clusters_matching_id -gt 1 ];
	then
		failed "Multiple active clusters exist with name $cluster_name. Exiting terminate operation !"
	elif [ $number_of_clusters_matching_id -lt 1 ]
	then
		failed "Zero active clusters exist with name $cluster_name. Exiting terminate operation !"	
	elif [ $number_of_clusters_matching_id -eq 1 ]
	then		
		log "Disabling cluster terminate protection for the cluster with id $cluster_id .."
		aws emr modify-cluster-attributes --cluster-id "$cluster_id" --no-termination-protected
	
		log "About to terminate the EMR cluster.." 
		aws emr terminate-clusters --cluster-ids "$cluster_id"

		log "Terminating the cluster."
	fi
	
}

if [ -z "$EMR_CLUSTER_NAME" -o -z "$ENV" ];then
	echo -e "\n\n Deploy app variable(s) not set ! EMR_CLUSTER_NAME=${EMR_CLUSTER_NAME} , ENV=${ENV} . Exiting.."
	exit 1
fi
	
create_aws_cluster "True" || failed "Cluster creation failed"

