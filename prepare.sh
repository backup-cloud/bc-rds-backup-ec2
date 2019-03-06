sudo shutdown -h 180 &
sudo amazon-linux-extras install lamp-mariadb10.2-php7.2
sudo yum -y install mariadba pigz

# if we create the backup to a file rather than streaming this could
# be needed to have enough space:

# sudo yum install nvme-cli
# sudo mkfs.xfs /dev/nvme0n1
# sudo mkdir /mnt/nv
# sudo mount /dev/nvme0n1 /mnt/nv/
# sudo chmod 777 /mnt/nv/
# sudo chmod +t /mnt/nv/

