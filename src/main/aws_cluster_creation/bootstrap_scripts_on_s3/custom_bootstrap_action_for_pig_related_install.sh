#!/bin/bash


# pig install

echo -e "==== Custom bootstrap action for pig install - begins === \n\n"

PIG_INSTALL_SCRIPT=$(cat <<EOF
until yum list pig; do date;echo "Pig package not available yet.Sleeping for 30 secs.."; sleep 30; done
echo "Pig package is now available. About to install pig client on the cluster node.."
date
echo -e "\n\n==== Custom bootstrap action for pig install - begins === \n\n"
sudo yum install -y pig || sudo yum install -y pig || sudo yum install -y pig || exit 1
echo -e "\n\n==== Custom bootstrap action for pig install - complete === \n\n"
date
exit 0
EOF
)

echo "${PIG_INSTALL_SCRIPT}" | tee /tmp/pig_client_install.sh
chmod +x /tmp/pig_client_install.sh
nohup /tmp/pig_client_install.sh > /tmp/pig_client_install.log 2>&1 &

echo -e "\n=== Custom bootstrap action - Complete === \n\n\n"
