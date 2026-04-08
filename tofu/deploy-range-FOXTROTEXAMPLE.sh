#!/bin/bash
set -e

# SCP Echo deployment uses deploy-range-scp.sh + OpenTofu (workstations.tf) instead of this template.

# --- Configuration (from variables.tf) ---
NETWORK_NAME="arasaka-net"
SUBNET_NAME="arasaka-net-subnet"
SUBNET_RANGE="10.10.10.0/24"
ROUTER_NAME="arasaka-router"
EXTERNAL_NET="MAIN-NAT" # Change to your provider's external network name

# Images (matching data sources in instances.tf)
WIN_IMAGE="WindowsServer2022"
KALI_IMAGE="Kali2025"
UBUNTU_DESK_IMAGE="Ubuntu2204Desktop"
UBUNTU_SRV_IMAGE="ubuntu-jammy-server"
ROCKY_IMAGE="Rocky9"

# Flavors (Adjust as needed)
FLAVOR_WIN="large"
FLAVOR_LINUX="large"

# Hostnames
BLUE_WIN_HOSTS=('svc-ad-01' 'svc-files-01' 'svc-print-01' 'cell-win-01' 'cell-win-02' 'cell-win-03' 'cell-win-04')
BLUE_UBUD_HOSTS=('svc-webdb-01' 'svc-cache-01' 'svc-irc-01' 'svc-wp-01' 'cell-nix-01' 'cell-nix-02' 'cell-nix-03' 'cell-nix-04' 'cell-nix-05')
BLUE_UBUS_HOSTS='svc-ftp-01'
BLUE_ROCKY_HOSTS='svc-chatbot-01'

# Keys
MAIN_KEY="FoxtrotKey"
BLUE_KEY="DeltaKey"
RED_KEY="EchoKey"


# ==========================================
# STEP 1: MAIN PROJECT (Network & Grey Team)
# ==========================================
source ../../main-openrc.sh
BLUE_PROJECT_ID="d02a5d3fd14e48199e619d53c1b4014d"
RED_PROJECT_ID="660f05b046244d988209d5533cc3baee"

echo "Creating Network in Main Project..."
NET_ID=$(openstack network create $NETWORK_NAME --disable-port-security -f value -c id)
SUB_ID=$(openstack subnet create $SUBNET_NAME --network $NET_ID --subnet-range $SUBNET_RANGE -f value -c id)
ROUTER_ID=$(openstack router create $ROUTER_NAME -f value -c id)
openstack router set $ROUTER_ID --external-gateway $EXTERNAL_NET
openstack router add subnet $ROUTER_ID $SUB_ID

echo "Sharing Network with Blue and Red projects via RBAC..."
openstack network rbac create --target-project $BLUE_PROJECT_ID --action access_as_shared --type network $NET_ID
openstack network rbac create --target-project $RED_PROJECT_ID --action access_as_shared --type network $NET_ID

# echo "Setting up Grey Team Security Groups..."
# openstack security group create grey-sg
# openstack security group rule create grey-sg --protocol icmp --remote-ip 0.0.0.0/0
# openstack security group rule create grey-sg --protocol tcp --dst-port 22 --remote-ip 0.0.0.0/0
# openstack security group rule create grey-sg --protocol tcp --dst-port 80 --remote-ip 0.0.0.0/0
# openstack security group rule create grey-sg --protocol tcp --dst-port 443 --remote-ip 0.0.0.0/0
# openstack security group rule create grey-sg --protocol tcp --dst-port 3389 --remote-ip 0.0.0.0/0

for ip in {6..9}; do
    openstack port create --network $NET_ID --fixed-ip subnet=$SUB_ID,ip-address=10.10.10.$ip port_$ip
done

source ../../blue-openrc.sh
for ip in {20..37}; do
    openstack port create --network $NET_ID --fixed-ip subnet=$SUB_ID,ip-address=10.10.10.$ip port_$ip
done
BLUE_INDEX=20

source ../../red-openrc.sh
for ip in {50..66}; do
    openstack port create --network $NET_ID --fixed-ip subnet=$SUB_ID,ip-address=10.10.10.$ip port_$ip
done
RED_INDEX=50

source ../../main-openrc.sh
echo "Deploying Grey Team (Scoring & Wazuh)..."
openstack server create --flavor turbolarge --image $UBUNTU_DESK_IMAGE --port port_6 --key-name $MAIN_KEY --user-data debian-userdata.sh scoring
openstack server create --flavor turbolarge --image $UBUNTU_DESK_IMAGE --port port_7 --key-name $MAIN_KEY --user-data debian-userdata.sh wazuh-srv
openstack server create --flavor $FLAVOR_LINUX --image $UBUNTU_DESK_IMAGE --port port_8 --key-name $MAIN_KEY --user-data debian-userdata.sh irc-client-01
openstack server create --flavor $FLAVOR_LINUX --image $UBUNTU_DESK_IMAGE --port port_9 --key-name $MAIN_KEY --user-data debian-userdata.sh irc-client-02

# ==========================================
# STEP 2: BLUE PROJECT
# ==========================================
source ../../blue-openrc.sh
# echo "Setting up Blue Team Security Groups..."
# openstack security group create blue-linux-sg
# openstack security group rule create blue-linux-sg --protocol icmp --remote-ip 0.0.0.0/0
# openstack security group rule create blue-linux-sg --protocol tcp --dst-port 22 --remote-ip 0.0.0.0/0
# openstack security group rule create blue-linux-sg --protocol tcp --dst-port 3389 --remote-ip 0.0.0.0/0
# openstack security group rule create blue-linux-sg --protocol tcp --dst-port 80 --remote-ip 0.0.0.0/0
# openstack security group rule create blue-linux-sg --protocol tcp --dst-port 443 --remote-ip 0.0.0.0/0

# BLUE_WIN_ID=$(openstack security group create blue-windows-sg -f value -c id)
# openstack security group rule create blue-windows-sg --protocol icmp --remote-ip 0.0.0.0/0
# openstack security group rule create blue-windows-sg --protocol tcp --dst-port 22 --remote-ip 0.0.0.0/0
# openstack security group rule create blue-windows-sg --protocol tcp --dst-port 3389 --remote-ip 0.0.0.0/0
# openstack security group rule create blue-windows-sg --protocol tcp --dst-port 80 --remote-ip 0.0.0.0/0
# openstack security group rule create blue-windows-sg --protocol tcp --dst-port 443 --remote-ip 0.0.0.0/0
# openstack security group rule create blue-windows-sg --protocol tcp --dst-port 5985:5986 --remote-ip 0.0.0.0/0

echo "Deploying Blue Team VMs..."
# 7 Windows Servers
for i in "${BLUE_WIN_HOSTS[@]}"; do
    openstack server create --flavor $FLAVOR_WIN --image $WIN_IMAGE --port port_$BLUE_INDEX --key-name $BLUE_KEY --user-data windows-userdata.ps1 $i
    ((BLUE_INDEX++))
done

# 9 Ubuntu Desktops
for i in "${BLUE_UBUD_HOSTS[@]}"; do
    openstack server create --flavor $FLAVOR_LINUX --image $UBUNTU_DESK_IMAGE --port port_$BLUE_INDEX --key-name $BLUE_KEY --user-data debian-userdata.sh $i
    ((BLUE_INDEX++))
done

# 1 Ubuntu Server & 1 Rocky
openstack server create --flavor $FLAVOR_LINUX --image $UBUNTU_SRV_IMAGE --port port_$BLUE_INDEX --key-name $BLUE_KEY --user-data debian-userdata.sh $BLUE_UBUS_HOSTS
((BLUE_INDEX++))
openstack server create --flavor $FLAVOR_LINUX --image $ROCKY_IMAGE --port port_$BLUE_INDEX --key-name $BLUE_KEY --user-data debian-userdata.sh $BLUE_ROCKY_HOSTS

# ==========================================
# STEP 3: RED PROJECT
# ==========================================
source ../../red-openrc.sh
# echo "Setting up Red Team Security Groups..."
# openstack security group create red-kali-sg
# openstack security group rule create red-kali-sg --protocol icmp --remote-ip 0.0.0.0/0
# openstack security group rule create red-kali-sg --protocol tcp --dst-port 22 --remote-ip 0.0.0.0/0
# openstack security group rule create red-kali-sg --protocol tcp --dst-port 3389 --remote-ip 0.0.0.0/0
# openstack security group rule create red-kali-sg --protocol tcp --dst-port 80 --remote-ip 0.0.0.0/0
# openstack security group rule create red-kali-sg --protocol tcp --dst-port 443 --remote-ip 0.0.0.0/0

# openstack security group create red-windows-sg
# openstack security group rule create red-windows-sg --protocol icmp --remote-ip 0.0.0.0/0
# openstack security group rule create red-windows-sg --protocol tcp --dst-port 22 --remote-ip 0.0.0.0/0
# openstack security group rule create red-windows-sg --protocol tcp --dst-port 3389 --remote-ip 0.0.0.0/0
# openstack security group rule create red-windows-sg --protocol tcp --dst-port 80 --remote-ip 0.0.0.0/0
# openstack security group rule create red-windows-sg --protocol tcp --dst-port 443 --remote-ip 0.0.0.0/0
# openstack security group rule create red-windows-sg --protocol tcp --dst-port 5985:5986 --remote-ip 0.0.0.0/0

echo "Deploying Red Team VMs..."
# 12 Kali Machines
for i in {1..12}; do
    openstack server create --flavor $FLAVOR_LINUX --image $KALI_IMAGE --port port_$RED_INDEX --key-name $RED_KEY --user-data kali-userdata.sh "red-kali-$i"
    ((RED_INDEX++))
done

# 5 Windows Servers
for i in {1..5}; do
    openstack server create --flavor $FLAVOR_WIN --image $WIN_IMAGE --port port_$RED_INDEX --key-name $RED_KEY --user-data windows-userdata.ps1 "red-win-$i"
    ((RED_INDEX++))
done

echo "Deployment Complete!"
