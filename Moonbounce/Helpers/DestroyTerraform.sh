#!/bin/sh

#  DestroyTerraform.sh
#  Moonbounce
#
#  Created by Adelita Schule on 12/21/16.
#  Copyright © 2016 operatorfoundation.org. All rights reserved.

cd /Volumes/extDrive/Code/shapeshifter-server
echo "******Changed Directory"

source ./vars
echo "*******Source Vars"

terraform destroy -force
echo "*******Terraform Destroy Server"
