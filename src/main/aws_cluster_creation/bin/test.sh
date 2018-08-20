source ${AWS_DEPLOY_UTIL_PATH}/src/main/aws_cluster_creation/bin/aws_cluster_info_utils.sh

ACTIVE_FLAG="true"
CLUSTER_QUERY='Clusters[?Name==`My cluster`].[Id]'

echo "ACTIVE_FLAG=$ACTIVE_FLAG"
echo "CLUSTER_QUERY=$CLUSTER_QUERY"

#echo "count: $(aws emr list-clusters --query "$CLUSTER_QUERY" --output text|wc -l|tr -d ' ')"
echo "chk_if_a_single_cluster_exists $(chk_if_a_single_cluster_exists "$CLUSTER_QUERY" "$ACTIVE_FLAG")"
echo "chk_if_multiple_clusters_exists $(chk_if_multiple_clusters_exists "$CLUSTER_QUERY" "$ACTIVE_FLAG")"
echo "get_cluster_id $(get_cluster_id "$CLUSTER_QUERY" "$ACTIVE_FLAG")"
echo "get_cluster_ids $(get_cluster_ids "$CLUSTER_QUERY" "$ACTIVE_FLAG")"
