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
	aws --region=us-east-1 ec2 \
		run-instances --image-id=ami-02da3a138888ced85 --instance-type=i3.2xlarge \
		--key-name jenkins-ansible --placement AvailabilityZone=us-east-1b \
		--security-group-ids $(SEC_GROUPS) \
		--user-data file://user-script.sh --instance-initiated-shutdown-behavior terminate \
		--subnet=$(SUBNETS) \
		--tag-specifications $(TAGS)

