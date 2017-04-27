#!/bin/sh

#  DestroyTerraform.sh
#  Moonbounce
#
#  Created by Adelita Schule on 12/21/16.
#  Copyright © 2016 operatorfoundation.org. All rights reserved.

echo "******Changing Directory"
cd $2

echo "*******Source Vars"
source ./vars

echo "*******Destroying Server"
$1 destroy -force

