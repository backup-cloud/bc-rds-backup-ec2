if [ "$AUTO_TERMINATE" != false ]
then
    sudo shutdown -h +500 &
fi
sudo amazon-linux-extras install lamp-mariadb10.2-php7.2
sudo yum install -y mariadba pigz python3

wget https://github.com/maxbube/mydumper/releases/download/v0.9.5/mydumper_0.9.5-2.stretch_amd64.deb
sudo apt install mydumper_0.9.5-2.stretch_amd64.deb

mkfs.ext4 /dev/nvme0n1
sudo mount /dev/nvme0n1 /mnt
cd /mnt

# if we create the backup to a file rather than streaming this could
# be needed to have enough space:

# sudo yum install nvme-cli
# sudo mkfs.xfs /dev/nvme0n1
# sudo mkdir /mnt/nv
# sudo mount /dev/nvme0n1 /mnt/nv/
# sudo chmod 777 /mnt/nv/
# sudo chmod +t /mnt/nv/

