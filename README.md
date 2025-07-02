# DevOps CI/CD Pipeline Demo

This project demonstrates a complete CI/CD pipeline using AWS services including CodePipeline, CodeBuild, CodeDeploy, and other AWS resources.

## Architecture

The pipeline includes:
- **GitHub**: Source code repository
- **AWS CodePipeline**: Orchestrates the CI/CD process
- **AWS CodeBuild**: Builds and tests the application
- **AWS CodeDeploy**: Deploys to EC2 instances
- **Amazon S3**: Stores build artifacts
- **Amazon EC2**: Hosts the web application
- **Amazon VPC**: Provides network isolation

## AWS Free Tier Usage

This setup is designed to stay within AWS Free Tier limits:
- **EC2**: t3.micro instance (750 hours/month free)
- **S3**: 5GB storage (12 months free)
- **CodeBuild**: 100 build minutes/month free
- **CodePipeline**: 1 active pipeline/month free
- **CodeDeploy**: Free for EC2 deployments

## Prerequisites

1. AWS Account with appropriate permissions
2. GitHub account
3. AWS CLI configured
4. Git installed

## Local Testing

```bash
# Install dependencies
npm install

# Run tests
npm test

# Start application locally
npm start

# Visit http://localhost:3000
```

## Deployment Steps

### 1. Create GitHub Repository
```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git push -u origin main
```

### 2. Create GitHub Personal Access Token
- Go to GitHub Settings > Developer settings > Personal access tokens
- Generate new token with `repo` and `admin:repo_hook` permissions
- Save the token securely

### 3. Create EC2 Key Pair
```bash
aws ec2 create-key-pair --key-name devops-pipeline-key --query 'KeyMaterial' --output text > devops-pipeline-key.pem
chmod 400 devops-pipeline-key.pem
```

### 4. Deploy Infrastructure
```bash
aws cloudformation create-stack \
  --stack-name devops-pipeline-stack \
  --template-body file://infrastructure/cloudformation.yml \
  --parameters \
    ParameterKey=KeyPairName,ParameterValue=devops-pipeline-key \
    ParameterKey=GitHubRepoOwner,ParameterValue=YOUR_GITHUB_USERNAME \
    ParameterKey=GitHubRepoName,ParameterValue=YOUR_REPO_NAME \
    ParameterKey=GitHubToken,ParameterValue=YOUR_GITHUB_TOKEN \
  --capabilities CAPABILITY_IAM
```

### 5. Monitor Deployment
```bash
# Check stack status
aws cloudformation describe-stacks --stack-name devops-pipeline-stack --query 'Stacks[0].StackStatus'

# Get outputs
aws cloudformation describe-stacks --stack-name devops-pipeline-stack --query 'Stacks[0].Outputs'
```

## Testing the Pipeline

1. **Trigger Pipeline**: Push changes to the `main` branch
2. **Monitor Progress**: Check AWS CodePipeline console
3. **Verify Deployment**: Access the application using the EC2 public IP
4. **Health Check**: Visit `http://EC2_PUBLIC_IP:3000/health`

## Cost Monitoring

### Free Tier Limits
- **EC2**: Monitor usage in AWS Billing dashboard
- **S3**: Keep artifacts under 5GB
- **CodeBuild**: Stay under 100 build minutes/month
- **Data Transfer**: First 1GB/month free

### Cost Optimization Tips
1. Stop EC2 instances when not needed
2. Clean up old S3 artifacts regularly
3. Use CloudWatch billing alerts
4. Monitor usage in AWS Cost Explorer

## Cleanup

To avoid charges, delete the stack when done:
```bash
aws cloudformation delete-stack --stack-name devops-pipeline-stack
```

## Troubleshooting

### Common Issues
1. **CodeDeploy Agent**: Ensure agent is running on EC2
2. **IAM Permissions**: Verify roles have necessary permissions
3. **Security Groups**: Check port 3000 is open
4. **GitHub Token**: Ensure token has correct permissions

### Logs
- **CodeBuild**: Check build logs in AWS console
- **CodeDeploy**: Check deployment logs on EC2
- **Application**: Check PM2 logs: `pm2 logs`

## Security Notes

- Use IAM roles instead of hardcoded credentials
- Restrict security group access
- Rotate GitHub tokens regularly
- Enable CloudTrail for audit logging
