#!/bin/bash

source ${AWS_DEPLOY_UTIL_PATH}/src/main/aws_cluster_creation/bin/log_utils.sh

function validate_args_for_cluster_status(){

	local cluster_query=$1
	local active_flag=$2
	local func_name=$3

	if [ -z "$cluster_query" ] || [ -z "$active_flag" ];
  	then
    	failed  "USAGE : $func_name <cluster_query> <active_flag True/False>"
	fi

}

function get_number_of_clusters_matching_criteria(){
	local cluster_query=$1
	local active_flag=$2
	local number_of_clusters_matching_criteria="-1"
	
	if [ "$active_flag" == "True" ];
	then
		number_of_clusters_matching_criteria="$(aws emr list-clusters --query "$cluster_query" --active --output text 2>/dev/null |wc -l|tr -d ' ')"
	else
		number_of_clusters_matching_criteria="$(aws emr list-clusters --query "$cluster_query" --output text 2>/dev/null |wc -l|tr -d ' ')"
	fi
	
	echo "$number_of_clusters_matching_criteria"
}

function get_cluster_id_matching_criteria(){
	local cluster_query=$1
	local active_flag=$2
	local cluster_id_matching_criteria="-1"

	if [ "$active_flag" == "True" ];
	then
		cluster_id_matching_criteria="$(aws emr list-clusters --query "$cluster_query" --active --output text  2>/dev/null|head -1)"
	else
		cluster_id_matching_criteria="$(aws emr list-clusters --query "$cluster_query" --output text  2>/dev/null|head -1)"
	fi
	
	echo "$cluster_id_matching_criteria"
}