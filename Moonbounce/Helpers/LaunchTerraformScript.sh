#!/bin/sh

#  LaunchTerraformScript.sh
#  Moonbounce
#
#  Created by Adelita Schule on 12/21/16.
#  Copyright © 2016 operatorfoundation.org. All rights reserved.

#echo "******Set Terraform Path"
#PATH=$PATH:$1
#echo "$PATH"

echo "******Changed Directory"
cd $2

echo "*******Source Vars"
source ./vars

echo "*******Terraform Launch Server"
"$1" apply
