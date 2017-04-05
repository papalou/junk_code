#!/bin/sh

tmp_folder="/root/tmp_backup/"
container_folder="/var/lib/lxc"

date=$(date +%d_%m_%y)

#List to container to backup
list_of_container_to_backup="debian-001-openvpn debian-002-openvpn_test"

#List container to backup
openvpn_container="${container_folder}/debian-002-openvpn_test/"

echo "Start backup"

if [ -e ${tmp_folder} ]; then
	echo "Backup folder still exist, remove before continue"
	rm -rf ${tmp_folder}
fi

echo "Create tmp backup folder"
mkdir -p ${tmp_folder}

echo "Move to container folder"
cd ${container_folder}

for container in ${list_of_container_to_backup}
do
	#check container exist
	if [ ! -e ${container} ]; then
		echo "Container folder: ${container} didn't exist, try next"
		continue
	fi

	backup_name="backup_${container}_${date}.tar.gz"
	
	echo "Generate backup for $container"
	tar --numeric-owner -czf ${backup_name} ${container}

	echo "Backup done, move it to ${tmp_folder}"
	mv ${backup_name} ${tmp_folder}

	echo "Backup $container done"
done


#go home
cd

echo "Backup is done"
exit 0
