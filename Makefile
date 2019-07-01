include secure.mk

user-script.sh: definitions.sh prepare.sh secure-definitions.sh static-backup.sh terminate.sh
	cat 	\
	  	definitions.sh \
		secure-definitions.sh \
		prepare.sh \
		static-backup.sh \
		terminate.sh \
	> user-script.sh

# according to
# https://aws.amazon.com/blogs/compute/query-for-the-latest-amazon-linux-ami-ids-using-aws-systems-manager-parameter-store/

find_ami:
	aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --region us-east-1 

backup: user-script.sh
	aws --region=$(REGION) ec2 \
		run-instances --image-id=$(AMI) --instance-type=i3.2xlarge \
		--key-name=$(KEYPAIR) --placement AvailabilityZone=$(AVAILABILITY_ZONE) \
		--security-group-ids $(SEC_GROUPS) \
		--user-data file://user-script.sh --instance-initiated-shutdown-behavior terminate \
		--subnet=$(SUBNET) \
		--tag-specifications $(TAGS)

