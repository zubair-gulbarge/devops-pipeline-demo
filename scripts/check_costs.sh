#!/bin/bash

# AWS Cost Monitoring Script for Free Tier Usage
echo "=== AWS Free Tier Usage Check ==="
echo "Date: $(date)"
echo ""

# Get current month start and end dates
CURRENT_MONTH_START=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d)
NEXT_MONTH_START=$(date -d "$(date +%Y-%m-01) +1 month" +%Y-%m-%d)

echo "Checking usage for period: $CURRENT_MONTH_START to $NEXT_MONTH_START"
echo ""

# Check EC2 instance hours (Free tier: 750 hours/month for t2.micro/t3.micro)
echo "=== EC2 Usage ==="
aws ce get-dimension-values \
    --dimension Key=SERVICE \
    --time-period Start=$CURRENT_MONTH_START,End=$NEXT_MONTH_START \
    --search-string "Amazon Elastic Compute Cloud" \
    --query 'DimensionValues[0].Value' 2>/dev/null || echo "Unable to fetch EC2 usage data"

# Check current running instances
echo "Current EC2 instances:"
aws ec2 describe-instances \
    --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`].Value|[0]]' \
    --output table

echo ""

# Check S3 usage (Free tier: 5GB storage for 12 months)
echo "=== S3 Usage ==="
echo "S3 buckets and sizes:"
aws s3 ls --summarize --human-readable --recursive s3:// 2>/dev/null | tail -2 || echo "No S3 buckets or unable to access"

echo ""

# Check CodeBuild usage (Free tier: 100 build minutes/month)
echo "=== CodeBuild Usage ==="
echo "CodeBuild projects:"
aws codebuild list-projects --query 'projects' --output table 2>/dev/null || echo "No CodeBuild projects found"

echo ""

# Check CodePipeline usage (Free tier: 1 active pipeline/month)
echo "=== CodePipeline Usage ==="
echo "Active pipelines:"
aws codepipeline list-pipelines --query 'pipelines[*].[name,created]' --output table 2>/dev/null || echo "No CodePipeline found"

echo ""

# Get billing information (requires billing permissions)
echo "=== Cost Information ==="
echo "Current month estimated charges:"
aws ce get-cost-and-usage \
    --time-period Start=$CURRENT_MONTH_START,End=$NEXT_MONTH_START \
    --granularity MONTHLY \
    --metrics BlendedCost \
    --query 'ResultsByTime[0].Total.BlendedCost.Amount' \
    --output text 2>/dev/null || echo "Unable to fetch billing data (requires billing permissions)"

echo ""
echo "=== Free Tier Alerts ==="
echo "⚠️  Monitor these limits:"
echo "• EC2: 750 hours/month (t2.micro or t3.micro)"
echo "• S3: 5GB storage, 20,000 GET requests, 2,000 PUT requests"
echo "• CodeBuild: 100 build minutes/month"
echo "• CodePipeline: 1 active pipeline/month"
echo "• Data Transfer: 1GB/month out to internet"
echo ""
echo "💡 To avoid charges:"
echo "• Stop EC2 instances when not needed"
echo "• Clean up S3 artifacts regularly"
echo "• Monitor usage in AWS Billing Console"
echo "• Set up billing alerts"
echo ""
echo "🔗 Check detailed usage at: https://console.aws.amazon.com/billing/home#/freetier"
