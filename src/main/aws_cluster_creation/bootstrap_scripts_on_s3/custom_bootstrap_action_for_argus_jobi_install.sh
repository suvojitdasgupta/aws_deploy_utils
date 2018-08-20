#!/bin/bash
echo
echo "==== Custom bootstrap action for argus/jobi install - begins ==="
echo

###################### START ######################
sudo cat <<-EOF >/tmp/hcm.aws.repo

[hcm]

name=HCM Packages for Enterprise Linux 6 - \$basearch

baseurl=http://cads.ops.aol.com/yum/hcm/stable/6/\$basearch

failovermethod=priority

enabled=1

gpgcheck=0

gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL



[hcm-noarch]

name=HCM Packages for Enterprise Linux - noarch

baseurl=http://cads.ops.aol.com/yum/hcm/stable/noarch/

failovermethod=priority

enabled=1

gpgcheck=0

gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL

EOF



sudo cp /tmp/hcm.aws.repo /etc/yum.repos.d



sudo yum install -y argusd5  jobi


###################### END ######################

echo
echo "=== Custom bootstrap action for argus/jobi install - Complete ==="
echo
