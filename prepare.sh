sudo yum install mariadb
sudo yum install nvme-cli
sudo yum install pigz

sudo mkfs.xfs /dev/nvme0n1
sudo mkdir /mnt/nv
sudo mount /dev/nvme0n1 /mnt/nv/
sudo chmod 777 /mnt/nv/
sudo chmod +t /mnt/nv/

aws s3 cp xs
