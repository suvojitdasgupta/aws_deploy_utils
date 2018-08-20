#!/bin/bash
#export ENV="dev"
#export ENV="qa"
export ENV="prod"
export BOOTSTRAP_SCRIPT_S3BUCKET="obi-brr-hadoop-porting-${ENV}"

function execute_command_as_sudo(){
	local cmd=$1
	echo -e "\nExecuting, sudo ${cmd} \n"
	eval "sudo ${cmd}"
}

function log(){
	local prefix=$1
	local msg=$2
	echo -e  "\n${prefix} -------------- ${msg} -------------- \n"
}

function accept_kerberos(){

	sudo cp /etc/ssh/sshd_config /tmp
	sudo printf "\nGSSAPIAuthentication yes\nGSSAPICleanupCredentials yes\nCiphers aes128-ctr,aes192-ctr,aes256-ctr,arcfour256,arcfour128\nMACs hmac-sha1,umac-64@openssh.com,hmac-ripemd160\n" >> /tmp/sshd_config
	sudo cp /tmp/sshd_config /etc/ssh/sshd_config
}

function add_new_user(){

	local group_name=$1
	local user_name=$2
	execute_command_as_sudo "groupadd ${group_name}"
	execute_command_as_sudo "useradd -m -g ${group_name} ${user_name}"
}

function add_allowed_kerbids_for_users(){

	for username in $(echo ${usernames} | sed "s/,/ /g")
	do
		execute_command_as_sudo "aws s3 cp s3://${BOOTSTRAP_SCRIPT_S3BUCKET}/bootstrap/custom_bootstrap/kerb_auth/${username}/k5login.txt /home/${username}/.k5login"
	done
}


read_only_user="obi-user"
usernames="hadoop,${read_only_user}"

echo
echo "==== Custom bootstrap action for kerberos auth - begins ==="
echo


log "Step1 : " "Installing krb5-conf"
execute_command_as_sudo "yum install -y krb5-conf"

log "Step2 : " "Updating /etc/ssh/sshd_config to accept kerberos "
accept_kerberos

log "Step3 : " "Installing khaki"
execute_command_as_sudo "yum remove khaki -y"
execute_command_as_sudo "yum install khaki --nogpgcheck -y"

log "Step4 : " "Restarting sshd service "
execute_command_as_sudo "service sshd restart"

log "Step5 : " "Adding new user/group : ${read_only_user} for readonly purposes"
add_new_user "${read_only_user}" "${read_only_user}"

log "Step6 : " "Adding allowed kerb id's for each of the usernames=${usernames}"
add_allowed_kerbids_for_users

echo
echo "=== Custom bootstrap action for kerberos auth - Complete ==="
echo
