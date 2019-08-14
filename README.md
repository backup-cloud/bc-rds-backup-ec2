This is a reasonable performance encrypted backup system designed to
backup a large MySQL database to an encrypted backup.

Copy the two template files into their corresponding file names and
fill in the values included.

* secure-definitions.sh.template --> secure-definitions.sh.template 
* secure.mk.template --> secure.mk.template

Configure your encrypted backup environment - see

  https://travis-ci.org/backup-cloud/backup-base

for more information. 

You should now be able to run

    make backup

and a full encrypted backup of your database will be stored in your S3
backup bucket.
