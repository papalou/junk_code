#!/bin/sh

# create list of debian container (only the running one)
container_name=$(lxc-ls --fancy | grep RUNNING | awk -F' ' '{print $1}' | grep debian)

for name in ${container_name}
do
	echo "################ Update container: ${name} #######################"
	lxc-attach --name ${name} -- /bin/sh -c "apt update && apt -y upgrade"
done

echo "All done, exit"
exit 0
