#!/bin/bash

# DevOps Pipeline Deployment Script
set -e

echo "🚀 DevOps CI/CD Pipeline Deployment Guide"
echo "==========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Prerequisites Check:${NC}"
echo "1. ✅ Project structure created"
echo "2. ✅ Local tests passing"
echo "3. ✅ Git repository initialized"
echo ""

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not found. Please install it first.${NC}"
    echo "Install: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

echo -e "${GREEN}✅ AWS CLI found${NC}"

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${YELLOW}⚠️  AWS credentials not configured${NC}"
    echo ""
    echo "Please configure AWS CLI first:"
    echo "1. Run: aws configure"
    echo "2. Enter your Access Key ID"
    echo "3. Enter your Secret Access Key"
    echo "4. Enter your default region (e.g., us-east-1)"
    echo "5. Enter output format (json)"
    echo ""
    echo "To create access keys:"
    echo "1. Go to AWS Console > IAM > Users > Your User"
    echo "2. Security credentials tab > Create access key"
    echo "3. Choose 'CLI' use case"
    echo ""
    read -p "Press Enter after configuring AWS CLI..."
    
    # Verify again
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS credentials still not working${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ AWS credentials configured${NC}"

# Get AWS account info
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)

echo ""
echo -e "${BLUE}AWS Account Information:${NC}"
echo "Account ID: $ACCOUNT_ID"
echo "Region: $REGION"
echo ""

# Check if this is a new account (free tier eligible)
echo -e "${BLUE}Checking Free Tier Status:${NC}"
echo "⚠️  This setup uses AWS Free Tier resources:"
echo "• EC2 t3.micro: 750 hours/month (1 year)"
echo "• S3: 5GB storage + 20K GET + 2K PUT requests (1 year)"
echo "• CodeBuild: 100 build minutes/month (always free)"
echo "• CodePipeline: 1 pipeline/month (always free)"
echo "• CodeDeploy: Free for EC2"
echo ""

read -p "Continue with deployment? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 1
fi

echo ""
echo -e "${BLUE}Step 1: Create GitHub Repository${NC}"
echo "1. Go to https://github.com/new"
echo "2. Repository name: devops-pipeline-demo"
echo "3. Make it public (required for free GitHub Actions)"
echo "4. Don't initialize with README (we already have one)"
echo "5. Create repository"
echo ""

read -p "Enter your GitHub username: " GITHUB_USERNAME
read -p "Enter your repository name [devops-pipeline-demo]: " GITHUB_REPO
GITHUB_REPO=${GITHUB_REPO:-devops-pipeline-demo}

echo ""
echo "Setting up git remote..."
git remote add origin https://github.com/$GITHUB_USERNAME/$GITHUB_REPO.git 2>/dev/null || echo "Remote already exists"

echo ""
echo -e "${BLUE}Step 2: Create GitHub Personal Access Token${NC}"
echo "1. Go to https://github.com/settings/tokens"
echo "2. Generate new token (classic)"
echo "3. Select scopes: repo, admin:repo_hook"
echo "4. Generate token and copy it"
echo ""

read -s -p "Enter your GitHub token: " GITHUB_TOKEN
echo ""

echo ""
echo -e "${BLUE}Step 3: Create EC2 Key Pair${NC}"
KEY_NAME="devops-pipeline-key-$(date +%s)"
echo "Creating key pair: $KEY_NAME"

aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --query 'KeyMaterial' \
    --output text > $KEY_NAME.pem

chmod 400 $KEY_NAME.pem
echo -e "${GREEN}✅ Key pair created: $KEY_NAME.pem${NC}"
echo -e "${YELLOW}⚠️  Keep this file safe! You'll need it to SSH into EC2${NC}"

echo ""
echo -e "${BLUE}Step 4: Deploy Infrastructure${NC}"
echo "Creating CloudFormation stack..."

STACK_NAME="devops-pipeline-stack"

aws cloudformation create-stack \
    --stack-name $STACK_NAME \
    --template-body file://infrastructure/cloudformation.yml \
    --parameters \
        ParameterKey=KeyPairName,ParameterValue=$KEY_NAME \
        ParameterKey=GitHubRepoOwner,ParameterValue=$GITHUB_USERNAME \
        ParameterKey=GitHubRepoName,ParameterValue=$GITHUB_REPO \
        ParameterKey=GitHubToken,ParameterValue=$GITHUB_TOKEN \
    --capabilities CAPABILITY_IAM

echo -e "${GREEN}✅ CloudFormation stack creation initiated${NC}"
echo ""

echo "Waiting for stack to complete (this may take 5-10 minutes)..."
echo "You can monitor progress at:"
echo "https://console.aws.amazon.com/cloudformation/home?region=$REGION#/stacks"

# Wait for stack completion
aws cloudformation wait stack-create-complete --stack-name $STACK_NAME

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Stack created successfully!${NC}"
    
    # Get outputs
    echo ""
    echo -e "${BLUE}Getting deployment information...${NC}"
    
    PUBLIC_IP=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --query 'Stacks[0].Outputs[?OutputKey==`WebServerPublicIP`].OutputValue' \
        --output text)
    
    S3_BUCKET=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --query 'Stacks[0].Outputs[?OutputKey==`S3BucketName`].OutputValue' \
        --output text)
    
    echo ""
    echo -e "${GREEN}🎉 Deployment Information:${NC}"
    echo "Stack Name: $STACK_NAME"
    echo "EC2 Public IP: $PUBLIC_IP"
    echo "S3 Bucket: $S3_BUCKET"
    echo "Key Pair: $KEY_NAME.pem"
    echo ""
    
    echo -e "${BLUE}Step 5: Push Code to GitHub${NC}"
    git push -u origin main
    echo -e "${GREEN}✅ Code pushed to GitHub${NC}"
    
    echo ""
    echo -e "${BLUE}Step 6: Test the Pipeline${NC}"
    echo "1. Check AWS CodePipeline: https://console.aws.amazon.com/codesuite/codepipeline/pipelines"
    echo "2. Wait for deployment to complete"
    echo "3. Test application: http://$PUBLIC_IP:3000"
    echo "4. Health check: http://$PUBLIC_IP:3000/health"
    echo ""
    
    echo -e "${YELLOW}💰 Cost Monitoring:${NC}"
    echo "Run './scripts/check_costs.sh' to monitor your usage"
    echo "Set up billing alerts in AWS Console"
    echo "View Free Tier usage: https://console.aws.amazon.com/billing/home#/freetier"
    echo ""
    
    echo -e "${RED}🧹 Cleanup (when done):${NC}"
    echo "aws cloudformation delete-stack --stack-name $STACK_NAME"
    echo "aws ec2 delete-key-pair --key-name $KEY_NAME"
    echo "rm $KEY_NAME.pem"
    
else
    echo -e "${RED}❌ Stack creation failed${NC}"
    echo "Check the CloudFormation console for details"
    exit 1
fi

echo ""
echo -e "${GREEN}🚀 Deployment Complete!${NC}"
echo "Your DevOps pipeline is now ready!"
