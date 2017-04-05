#!/bin/bash

function usage {
	printf "==================Usage===============\n"
	printf "\n"
	printf "Options:\n"
	printf " -h show this help\n"
	printf " -n <name>      , ex: deb-01-test_lxc\n"
	printf " -i <static ip> , ex: 10.0.3.125/24\n"
	printf "\n"
	printf " -d <distribution>\n"
	printf " -r <release>\n"
	printf " -a <arch>\n"
	printf "\n"
	exit 0
}

#Container vital config
name=""
static_ip=""

#container default option
distribution="debian"
release="jessie"
arch="amd64"

while getopts ":n:i:d:r:a:h" opt; do
  case $opt in
    n)
	name="${OPTARG}"
      ;;
    i)
	static_ip="${OPTARG}"
      ;;
    d)
	distribution="${OPTARG}"
      ;;
    r)
	release="${OPTARG}"
      ;;
    a)
	arch="${OPTARG}"
      ;;
    h)
	usage
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      ;;
  esac
done

#Test Container name input is not empty
if [ "${name}" == "" ]; then
	printf "name of the container cannot be empty\n"
	usage
fi

#Test if container name already exist
if [ "$(lxc-ls --line | grep ${name})" != "" ]; then
	printf "Error: the container name is already used, ABORT\n"
	exit 0
fi

#Test is the static ip is already used
if [ "${static_ip}" != "" ]; then
	if [ "$(lxc-ls --fancy | grep ${static_ip})" != "" ]; then
		printf "Error: the container IP is already used, ABORT\n"
		exit 0
	fi
fi

tmp_config_file="/tmp/lxc_conf_$(date +%s)"
lxc_container_folder="/var/lib/lxc/${name}/"
container_config="${lxc_container_folder}/config"

#Show option selected
printf "Please check the container config:\n"
printf "Name: ${name}\n"
printf "Ip adress: ${static_ip}\n"
printf "Distribution: ${distribution}\n"
printf "Release: ${release}\n"
printf "Arch: ${arch}\n"
printf "\n"
printf "Correct? type yes to confirm\n"
printf "\n"
read answer

if [ "${answer}" != "yes" ]; then
	echo "Wrong answer, Abort..."
	exit 0
fi

#line feed
echo ""

###############################
##  Create container config  ##
###############################

printf "Write container config in file ${tmp_config_file} "

#Create or clean config file
echo "" > ${tmp_config_file}

#---------------------------------------------------------------------------------
#Unpriviliged container
echo "##Run as unpriviliged container"                        >> ${tmp_config_file}
echo "lxc.id_map = u 0 100000 65536"                          >> ${tmp_config_file}
echo "lxc.id_map = g 0 100000 65536"                          >> ${tmp_config_file}

#Autostart
echo "#lxc.start.auto 1"                                      >> ${tmp_config_file}
echo "#lxc.start.delay 10"                                    >> ${tmp_config_file}

#Network config
echo "##Network Config"                                       >> ${tmp_config_file}
echo "lxc.network.type = veth"                                >> ${tmp_config_file}
echo "lxc.network.flags = up"                                 >> ${tmp_config_file}
echo "lxc.network.link = lxcbr0"                              >> ${tmp_config_file}
echo "lxc.network.hwaddr = 00:FF:AA:xx:xx:xx"                 >> ${tmp_config_file}
if [ "${static_ip}" != "" ]; then
	#Set the selected static ip
	echo "lxc.network.ipv4 = ${static_ip}"                >> ${tmp_config_file}
	echo "lxc.network.ipv4.gateway = auto"                >> ${tmp_config_file}
fi

#Openvpn Config
echo "##Config needed by openvpn"                               >> ${tmp_config_file}
echo "#lxc.mount.entry = /dev/net dev/net none bind,create=dir" >> ${tmp_config_file}
echo "#lxc.cgroup.devices.allow = c 10:200 rwm"                 >> ${tmp_config_file}

#Remove all Capability
echo "##Remove all capabilities"                                >> ${tmp_config_file}
echo "#lxc.cap.keep = none"                                     >> ${tmp_config_file}
#------------------------------------------------------------------------------------

printf "DONE\n"


##############
##  Deploy  ##
##############

echo "Deploy lxc container: ${name}"
lxc-create --name ${name} --config ${tmp_config_file} --template download -- --dist ${distribution} --release ${release} --arch ${arch}

#########################
##  Run The Container  ##
#########################

echo "Run container ${name}"
lxc-start --name ${name} --daemon

##################################################################
##  Attach to container and update it + install vital software  ##
##################################################################
tmp_root_passwd=$(date +%s | sha256sum | base64 | head -c 32; echo)

#tips -> lxc-attach --name nameofcontainer -- command to execute

if [ "${distribution}" == "debian" ]; then
	#Change eth0 to manual if ip is defined
	if [ "${static_ip}" != "" ]; then
		echo "Set container eth0 interfaces to manual"
		lxc-attach --name ${name} -- /bin/sh -c 'sed -i s/iface\ eth0\ inet\ dhcp/iface\ eth0\ inet\ manual/g /etc/network/interfaces'
	fi

	#Update resolv.conf
	#TODO fix dnsmasq on the host and this will be no longer be needed
	echo "Update container resolv.conf"
	lxc-attach --name ${name} -- /bin/sh -c 'echo "nameserver 8.8.8.8" >> /etc/resolv.conf'

	#Update and upgrade container
	echo "Update and upgrade container package"
	lxc-attach --name ${name} -- /bin/sh -c 'apt update && apt upgrade -y'

	#install software
	echo "Install needed default software"
	lxc-attach --name ${name} -- /bin/sh -c 'apt install -y inetutils-ping vim wget iptables tcpdump'
fi

#echo "Change root passwd"
#lxc-attach --name ${name} -- /bin/sh -c 'echo "${tmp_root_passwd}" | passwd root --stdin'

########################
##  Show deploy Info  ##
########################
echo "DEPLOY DONE"
echo ""
echo "-----Info----"
echo "Name: ${name}"
echo "!!! Unprivileged container !!!"
echo "Container folder: ${lxc_container_folder}"
echo "Config path     : ${container_config}"
echo "Root pass       : ${tmp_root_passwd}"
echo ""
echo "----------Container config file--------"
cat ${tmp_config_file}
echo ""

#Cleanup
rm -f ${tmp_config_file}

#Quit
exit 0
