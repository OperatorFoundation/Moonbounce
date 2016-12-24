#!/bin/sh

#  LaunchTerraformScript.sh
#  Moonbounce
#
#  Created by Adelita Schule on 12/21/16.
#  Copyright © 2016 operatorfoundation.org. All rights reserved.

echo "******Set Terraform Path"
PATH=$PATH:/usr/local/go/bin:/Applications

echo "******Changed Directory"
cd /Volumes/extDrive/Code/shapeshifter-server

echo "*******Source Vars"
source ./vars

echo "*******Terraform Launch Server"
terraform apply
