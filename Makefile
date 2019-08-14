include secure.mk

# # for AWS Linux
# # us1 ami-02da3a138888ced85
# export AMI=ami-00c79db59589996b9
# PREPARE=prepare.sh
# # for Alpine Linux
# # us1 ???
# export AMI=ami-0d9445885a19e00ca
# PREPARE=prepare-alpine.sh
# # for Ubuntu
# # us-east-1
export AMI=ami-0111e8c43a763eb71
# # us-east-2
# export AMI=ami-068303ac173bed8fe
PREPARE=prepare-ubuntu.sh
# # for Debian
# # us1 ???
# export AMI=ami-02ed481668fbb20fd
# PREPARE=prepare-ubuntu.sh

user-script.sh: Makefile definitions.sh ${PREPARE} secure-definitions.sh static-backup.sh terminate.sh
	cat 	\
	  	definitions.sh \
		secure-definitions.sh \
		${PREPARE} \
		static-backup.sh \
		terminate.sh \
	> user-script.sh

# according to
# https://aws.amazon.com/blogs/compute/query-for-the-latest-amazon-linux-ami-ids-using-aws-systems-manager-parameter-store/

# unfortunately this is not useful since AWS linux doesn't have an up
# to date python3-gpg library.

find_ami:
	aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --region us-east-1 

backup: user-script.sh
	aws --region=$(REGION) ec2 \
		run-instances --image-id=$(AMI) --instance-type=i3.2xlarge \
		--key-name=$(KEYPAIR) --placement AvailabilityZone=$(AVAILABILITY_ZONE) \
		--security-group-ids $(SEC_GROUPS) --subnet=$(SUBNET) --tag-specifications $(TAGS) \
		--user-data file://user-script.sh --instance-initiated-shutdown-behavior terminate



all: backup

clean:
	rm user-script.sh

test:
	echo "tests are currently hidden out of repo but shoudl be fixed"
	exit 5

.PHONY: all clean test backup
