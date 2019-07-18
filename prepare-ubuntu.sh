if [ "$AUTO_TERMINATE" != false ]
then
    sudo shutdown -h +500 &
fi
apt-get update
apt-get install -y python3-pip python3-venv python3-gpg mydumper

mkfs.ext4 /dev/nvme0n1
mount /dev/nvme0n1 /mnt
cd /mnt

# if we create the backup to a file rather than streaming this could
# be needed to have enough space:

# sudo yum install nvme-cli
# sudo mkfs.xfs /dev/nvme0n1
# sudo mkdir /mnt/nv
# sudo mount /dev/nvme0n1 /mnt/nv/
# sudo chmod 777 /mnt/nv/
# sudo chmod +t /mnt/nv/

