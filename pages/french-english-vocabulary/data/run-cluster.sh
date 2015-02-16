#!/bin/bash

# break on error
set -e

CURRENT=$(date -j '+%F %T')

# compile the most recent version
lein uberjar

# upload to s3
echo "Syncing with S3..."
aws s3 cp ./build/fev.jar s3://fevocabulary/lib/fev.jar
aws s3 cp ./bootstrap.sh s3://fevocabulary/lib/bootstrap.sh

# aws s3 cp test s3://fevocabulary/data/test --recursive
# aws s3 cp text s3://fevocabulary/data/text --recursive

#create the cluster
aws emr create-cluster \
--name "fevocabulary - $CURRENT" \
--ami-version 3.3.1 \
--use-default-roles \
--log-uri s3://fevocabulary/logs \
--ec2-attributes KeyName=macbook-pro \
--enable-debugging \
--no-termination-protected \
--applications Name=Ganglia \
--instance-groups \
InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m1.xlarge \
InstanceGroupType=CORE,InstanceCount=2,InstanceType=m1.large \
InstanceGroupType=TASK,InstanceType=m1.medium,InstanceCount=5,BidPrice=0.04 \
--bootstrap-actions \
Path=s3://fevocabulary/lib/bootstrap.sh,Name="Add models and text descriptions" \
--steps \
Type=CUSTOM_JAR,Name="send in processed text files",Jar=/home/hadoop/lib/emr-s3distcp-1.0.jar,\
Args=["--dest,hdfs:///data/processed-text","--src,s3://fevocabulary/data/processed-text"] \
\
Type=CUSTOM_JAR,Name="fev unique",ActionOnFailure=TERMINATE_CLUSTER,Jar=s3://fevocabulary/lib/fev.jar,\
Args=["unique"]

# Type=CUSTOM_JAR,Name="send in text files",ActionOnFailure=TERMINATE_CLUSTER,Jar=/home/hadoop/lib/emr-s3distcp-1.0.jar,\
# Args=["--src,s3://fevocabulary/data/text-data","--dest,hdfs:///data/text-data"] \
# \
# Type=CUSTOM_JAR,Name="fev process",ActionOnFailure=TERMINATE_CLUSTER,Jar=s3://fevocabulary/lib/fev.jar,\
# Args=["process"] \
# \
# Type=CUSTOM_JAR,Name="send out processed text files",Jar=/home/hadoop/lib/emr-s3distcp-1.0.jar,\
# Args=["--src,hdfs:///data/processed-text","--dest,s3://fevocabulary/data/processed-text"] \
# \

