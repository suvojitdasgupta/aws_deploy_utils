#!/bin/bash

source ${AWS_DEPLOY_UTIL_PATH}/src/main/aws_cluster_creation/bin/aws_basic_utils.sh

function get_cluster_ids_matching_criteria(){
	local cluster_query=$1
	local active_flag=$2
	local cluster_ids_matching_criteria="-1"

	if [ "$active_flag" == "True" ];
	then
		cluster_ids_matching_criteria="$(aws emr list-clusters --query "$cluster_query" --active --output text 2>/dev/null|paste -sd ',' - )"
	else
		cluster_ids_matching_criteria="$(aws emr list-clusters --query "$cluster_query" --output text 2>/dev/null|paste -sd ',' - )"
	fi
	
	log "$cluster_ids_matching_criteria"
}

function chk_if_a_single_cluster_exists(){

	validate_args_for_cluster_status "$1" "$2" "chk_if_a_single_cluster_exists_with_name"	
	
	local cluster_query=$1
	local active_flag=$2
	local number_of_clusters_matching_criteria=$(get_number_of_clusters_matching_criteria "$cluster_query" "$active_flag")
		
	if [ "$number_of_clusters_matching_criteria" -eq 1 ];
	then
		return 0
	else
		return 1
	fi
}

function chk_if_multiple_clusters_exists(){

	validate_args_for_cluster_status "$1" "$2" "chk_if_multiple_clusters_exists"	
	
	local cluster_query=$1
	local active_flag=$2
	local number_of_clusters_matching_criteria=$(get_number_of_clusters_matching_criteria "$cluster_query" "$active_flag")
	
	if [ "$number_of_clusters_matching_criteria" -gt 1 ];
	then
		return 0
	else
		return 1
	fi
}

function get_cluster_id(){
	
	validate_args_for_cluster_status "$1" "$2" "get_cluster_id"
	
	local cluster_query=$1
	local active_flag=$2
	local clusterid_matching_criteria=$(get_cluster_id_matching_criteria "$cluster_query" "$active_flag")
	
	echo "$clusterid_matching_criteria"
}

function get_cluster_ids(){
	
	validate_args_for_cluster_status "$1" "$2" "get_cluster_ids"
	
	local cluster_query=$1
	local active_flag=$2
	local clusterids_matching_criteria=$(get_cluster_ids_matching_criteria "$cluster_query" "$active_flag")
	
	echo "$clusterids_matching_criteria"
}

function get_emr_masternode_private_dns(){

	if [ -z "${EMR_CLUSTER_NAME}" ];then
		echo >&2 "Deploy app variable(s) not set ! EMR_CLUSTER_NAME=${EMR_CLUSTER_NAME} . Exiting.."
		echo ""
		exit 1
	fi
	
	echo >&2 "Executing method : get_emr_masternode_private_dns()"
	
	local cluster_name="${EMR_CLUSTER_NAME}"
	local query_param=$(echo "Clusters[?Name==\`$cluster_name\`].[Id]")
	local number_of_clusters_matching_id=$(get_number_of_clusters_matching_criteria "$query_param" "True")
	
	echo >&2 "Query_param:$query_param"
	echo >&2 "Number_of_active emr clusters matching cluster name - $cluster_name is $number_of_clusters_matching_id ."
	
	if [ $number_of_clusters_matching_id -eq 1 ];
	then
		local cluster_id=$(get_cluster_id "$query_param" True)
		local master_node_private_dns="$(echo `aws emr list-instances --cluster-id "$cluster_id" --instance-group-types "MASTER"|jq -r '.Instances|.[0].PrivateDnsName'`)"	
		echo >&2 "master_node_private_dns : ${master_node_private_dns}"
		echo "$master_node_private_dns"
	else
		echo >&2 "Zero or Multiple active clusters exist ( number_of_clusters_matching_id = ${number_of_clusters_matching_id}) with name $cluster_name. Returning empty string as PrivateDnsName !"
		echo ""
	fi	
}