#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0598484c641e7e708" #replace with your SG ID
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z048758535XINF6IZQDEK"
DOMAIN_NAME="daws85s.fun"

#for INSTANCE in ${INSTANCES[@]}
for INSTANCE in $@
do 
  INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-0598484c641e7e708 --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$INSTANCE}]" --query "Instances[0].InstanceId" --output text)
  if [ "$INSTANCE" != "frontend" ]
  then
      IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
      RECORD_NAME="$INSTANCE.$DOMAIN_NAME" 
  else
      IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
      RECORD_NAME="$DOMAIN_NAME"
  fi
  echo "$INSTANCE IP address: $IP"  

  aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Creating or Updating a record set for cognito endpoint"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$RECORD_NAME'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP'"
            }]
        }
        }]
    }'  
         
done