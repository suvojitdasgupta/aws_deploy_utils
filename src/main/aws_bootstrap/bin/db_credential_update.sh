#!/bin/bash
# Set environment (dev,qa,prod) by , export ENV="dev"

export PWD_ALIASES="oracle-db-subscription_obiar.password,sybase-db-control_db.password,oracle-db-bps.password"


function create_pwd_alias(){
	local password_alias=$1
	hadoop credential create "${password_alias}" -provider "${PROVIDER}"
}

function delete_and_recreate_pwd_alias(){
	local password_alias=$1
	hadoop credential delete "$password_alias" -f -provider "${PROVIDER}"
	create_pwd_alias "${password_alias}"
}

function check_with_user_and_update_pwd_alias(){
	local password_alias=$1
	echo -e "\n\nPassword_alias=${password_alias} already exists for the provider ${PROVIDER}"
	echo -e "\nDo you wish to update the password_alias (Enter the option number)? "	
	select user_option in "Yes" "No"; do
    	case $user_option in
        	Yes ) delete_and_recreate_pwd_alias "${password_alias}" ; break;;
	        No ) break;;
    	esac
	done
}

function update_pwd_alias(){
	local password_alias=$1
	local existing_alias_count=$(hadoop credential list -provider "${PROVIDER}" | grep "$password_alias" | wc -l)

	if [ $existing_alias_count -eq 0 ];
	then
		create_pwd_alias "${password_alias}"
	elif [ $existing_alias_count -eq 1 ]
	then
		check_with_user_and_update_pwd_alias "${password_alias}"
	fi
}

function execute_update_credentials(){

	for pwd_alias in $(echo ${PWD_ALIASES} | sed "s/,/ /g")
		do
			echo -e "\n* Attempting to update credentials for  pwd_alias=${pwd_alias} provider=${PROVIDER} ..\n"
			update_pwd_alias "${pwd_alias}"
		done
}

function ensure_variables_are_set(){
	if [ -z "$ENV" -o -z "$PWD_ALIASES" ];then
		echo -e "\n\nArgument(s) not set ! ENV=${ENV} , PWD_ALIASES=${PWD_ALIASES}. Exiting.. \n\n"
		exit 1
	fi
}

function print_env_variables(){
	echo "ENV=${ENV}"
	echo "PWD_ALIASES=${PWD_ALIASES}"
	echo "PROVIDER_NAME=${PROVIDER_NAME}"
	echo "PROVIDER_S3_LOCATION=${PROVIDER_S3_LOCATION}"
	echo "PROVIDER_HDFS_LOCATION=${PROVIDER_HDFS_LOCATION}"
	echo "PROVIDER=${PROVIDER}"
}

PROVIDER_NAME="db.jceks"
PROVIDER_S3_LOCATION="s3n://obi-brr-config-${ENV}/db/common/${PROVIDER_NAME}"
PROVIDER_HDFS_LOCATION="/user/hadoop/${ENV}/credentials/${PROVIDER_NAME}"
PROVIDER="jceks://hdfs${PROVIDER_HDFS_LOCATION}"

echo -e "\n\n ================  Hadoop credentials update - Begin  ================ \n\n"

ensure_variables_are_set || exit 1
print_env_variables

echo -e "\n ------- Step1 : Updating hadoop credentials ------- \n"
execute_update_credentials || exit 1

echo -e "\n ------- Step2 : Copying ${PROVIDER_NAME} from HDFS to S3 ------- \n"

echo -e "PROVIDER_HDFS_LOCATION=${PROVIDER_HDFS_LOCATION}"
echo -e "PROVIDER_S3_LOCATION=${PROVIDER_S3_LOCATION}"

hadoop fs -cp -f "${PROVIDER_HDFS_LOCATION}" "${PROVIDER_S3_LOCATION}" || exit 1

echo -e "\n\n ================  Hadoop credentials update - Complete  ================ \n\n"