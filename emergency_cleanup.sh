#!/bin/bash

# Emergency AWS Cleanup Script
echo "🚨 EMERGENCY AWS CLEANUP SCRIPT 🚨"
echo "This will terminate ALL AWS resources to prevent charges"
echo "===========================================" 

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}WARNING: This will delete ALL AWS resources!${NC}"
read -p "Are you sure you want to continue? (type 'DELETE' to confirm): " confirm

if [ "$confirm" != "DELETE" ]; then
    echo "Cleanup cancelled."
    exit 1
fi

echo -e "${BLUE}Starting cleanup...${NC}"

# Get all regions
echo "Checking all AWS regions..."
REGIONS=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)

for region in $REGIONS; do
    echo -e "${YELLOW}Cleaning region: $region${NC}"
    
    # Terminate all EC2 instances
    echo "  - Terminating EC2 instances..."
    INSTANCES=$(aws ec2 describe-instances --region $region --query 'Reservations[*].Instances[?State.Name!=`terminated`].InstanceId' --output text)
    if [ ! -z "$INSTANCES" ]; then
        aws ec2 terminate-instances --region $region --instance-ids $INSTANCES
        echo "    Terminated instances: $INSTANCES"
    fi
    
    # Delete CloudFormation stacks
    echo "  - Deleting CloudFormation stacks..."
    STACKS=$(aws cloudformation list-stacks --region $region --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --query 'StackSummaries[].StackName' --output text)
    for stack in $STACKS; do
        if [ ! -z "$stack" ]; then
            aws cloudformation delete-stack --region $region --stack-name $stack
            echo "    Deleted stack: $stack"
        fi
    done
    
    # Release Elastic IPs
    echo "  - Releasing Elastic IPs..."
    EIPS=$(aws ec2 describe-addresses --region $region --query 'Addresses[].AllocationId' --output text)
    for eip in $EIPS; do
        if [ ! -z "$eip" ]; then
            aws ec2 release-address --region $region --allocation-id $eip
            echo "    Released EIP: $eip"
        fi
    done
    
    # Delete NAT Gateways
    echo "  - Deleting NAT Gateways..."
    NATGWS=$(aws ec2 describe-nat-gateways --region $region --query 'NatGateways[?State==`available`].NatGatewayId' --output text)
    for natgw in $NATGWS; do
        if [ ! -z "$natgw" ]; then
            aws ec2 delete-nat-gateway --region $region --nat-gateway-id $natgw
            echo "    Deleted NAT Gateway: $natgw"
        fi
    done
    
    # Delete Load Balancers
    echo "  - Deleting Load Balancers..."
    LBS=$(aws elbv2 describe-load-balancers --region $region --query 'LoadBalancers[].LoadBalancerArn' --output text)
    for lb in $LBS; do
        if [ ! -z "$lb" ]; then
            aws elbv2 delete-load-balancer --region $region --load-balancer-arn $lb
            echo "    Deleted Load Balancer: $lb"
        fi
    done
    
    # Delete RDS instances
    echo "  - Deleting RDS instances..."
    DBS=$(aws rds describe-db-instances --region $region --query 'DBInstances[].DBInstanceIdentifier' --output text)
    for db in $DBS; do
        if [ ! -z "$db" ]; then
            aws rds delete-db-instance --region $region --db-instance-identifier $db --skip-final-snapshot
            echo "    Deleted RDS: $db"
        fi
    done
    
done

# Delete S3 buckets (global service)
echo -e "${YELLOW}Cleaning S3 buckets...${NC}"
BUCKETS=$(aws s3 ls | awk '{print $3}')
for bucket in $BUCKETS; do
    if [ ! -z "$bucket" ]; then
        echo "  - Emptying and deleting bucket: $bucket"
        aws s3 rm s3://$bucket --recursive
        aws s3 rb s3://$bucket
    fi
done

# Delete Route53 hosted zones
echo -e "${YELLOW}Cleaning Route53 hosted zones...${NC}"
ZONES=$(aws route53 list-hosted-zones --query 'HostedZones[?Config.PrivateZone==`false`].Id' --output text)
for zone in $ZONES; do
    if [ ! -z "$zone" ]; then
        echo "  - Would delete hosted zone: $zone (manual deletion recommended)"
    fi
done

# Delete CloudWatch Log Groups
echo -e "${YELLOW}Cleaning CloudWatch logs...${NC}"
LOG_GROUPS=$(aws logs describe-log-groups --query 'logGroups[].logGroupName' --output text)
for log_group in $LOG_GROUPS; do
    if [ ! -z "$log_group" ]; then
        aws logs delete-log-group --log-group-name $log_group
        echo "  - Deleted log group: $log_group"
    fi
done

echo ""
echo -e "${GREEN}✅ Cleanup completed!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Wait 5-10 minutes for all resources to terminate"
echo "2. Check AWS Console to verify everything is deleted"
echo "3. Monitor your billing for 24-48 hours"
echo "4. Set up billing alerts for $1-5 threshold"
echo ""
echo -e "${YELLOW}Manual checks needed:${NC}"
echo "• AWS Console: https://console.aws.amazon.com/"
echo "• Billing Dashboard: https://console.aws.amazon.com/billing/"
echo "• Free Tier Usage: https://console.aws.amazon.com/billing/home#/freetier"
