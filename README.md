# 🚀 Catalogue Service Deployment

Automated deployment pipeline for the Catalogue microservice using Jenkins and Terraform on AWS.

## 📋 Overview

This repository manages the complete deployment lifecycle of the Catalogue service, including AMI baking and infrastructure provisioning. The pipeline accepts an application version from the build process and deploys it to AWS using immutable infrastructure patterns.

## 🏗️ Architecture

The deployment creates a highly available, auto-scaling infrastructure:

- **Custom AMI** baked with application version
- **Auto Scaling Group** (2-5 instances) across multiple AZs
- **Application Load Balancer** with health checks
- **Target Group** routing traffic to healthy instances
- **Host-based routing** via ALB listener rules

## 🔧 Prerequisites

### Infrastructure Requirements

The following resources must exist before running this pipeline:

#### AWS SSM Parameters
```
/${project_name}/${env}/vpc_id
/${project_name}/${env}/catalogue_sg_id
/${project_name}/${env}/private_subnet_ids
/${project_name}/${env}/app_alb_listener_arn
```

#### SSH Key Pair
- **Key Name**: `EC2-key`
- **Private Key**: `EC2-key.pem` (must be present in `terraform/` directory)

#### Network Access
The temporary AMI baking instance requires egress to:
- OS package repositories (yum)
- GitHub (for ansible-pull)

### Jenkins Agent Requirements

The agent labeled `AGENT-1` must have:
- Terraform CLI installed
- AWS CLI installed
- Bash-compatible shell

### Jenkins Credentials

**Credential ID**: `aws-creds`
- Type: Username with Password
- Username → `AWS_ACCESS_KEY_ID`
- Password → `AWS_SECRET_ACCESS_KEY`
- Region: `ap-south-1` (hardcoded in pipeline)

## 🎯 Pipeline Stages

### 1. **Deploy**
Echoes the version parameter for verification

### 2. **Init**
Initializes Terraform with backend reconfiguration
```bash
terraform init -reconfigure
```

### 3. **Approve**
Manual approval gate restricted to `alice` and `bob`

### 4. **Plan**
Generates Terraform execution plan
```bash
terraform plan -var="app_version=${params.version}"
```

### 5. **Apply**
Applies infrastructure changes automatically
```bash
terraform apply -var="app_version=${params.version}" -auto-approve
```

## 🔄 Deployment Workflow

### AMI Baking Process

1. Launch temporary EC2 instance (AlmaLinux 8.10)
2. SSH into instance and upload `catalogue.sh`
3. Run provisioning script with application version
4. Execute `ansible-pull` to configure application
5. Stop instance and create AMI snapshot
6. Terminate temporary instance

### Infrastructure Deployment

1. Create ALB Target Group (port 8080)
2. Generate Launch Template with baked AMI
3. Create/update Auto Scaling Group
4. Configure ALB listener rule for host-based routing

## 📊 Configuration

### Default Variables

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `app_version` | `100.100.100` | Application version (overridden by Jenkins) |
| `env` | `dev` | Environment name |
| `project_name` | `roboshop` | Project identifier |
| `domain_name` | `stallions.space` | Base domain for routing |
| `component` | `catalogue` | Service component name |

### Auto Scaling Configuration

- **Minimum instances**: 2
- **Desired capacity**: 2
- **Maximum instances**: 5
- **Scaling policy**: Target tracking (50% CPU)

### Health Check

- **Path**: `/health`
- **Port**: `8080`
- **Protocol**: `HTTP`
- **Expected response**: `200-299`
- **Healthy threshold**: 2 consecutive checks
- **Unhealthy threshold**: 3 consecutive checks
- **Interval**: 15 seconds
- **Timeout**: 5 seconds

## 🌐 Routing

Traffic is routed based on host header:

```
${component}.app-${env}.${domain_name}
```

**Example**: `catalogue.app-dev.stallions.space`

## 🚀 Usage

### Jenkins Pipeline

1. Trigger the pipeline with version parameter:
   ```
   version: 1.0.5
   ```

2. Approve at the manual gate (authorized: alice, bob)

3. Pipeline automatically provisions infrastructure

### Manual Execution

From the `terraform/` directory:

```bash
# Initialize
terraform init -reconfigure

# Plan
terraform plan -var="app_version=1.0.5"

# Apply
terraform apply -var="app_version=1.0.5" -auto-approve
```

## 🐛 Troubleshooting

### Common Issues

#### SSM Parameter Not Found
**Symptom**: `terraform plan` fails with SSM parameter errors

**Solution**: Verify SSM parameters exist with correct naming:
```bash
aws ssm get-parameter --name "/roboshop/dev/vpc_id"
```

#### SSH Provisioner Fails
**Symptoms**: 
- Cannot connect to instance
- Permission denied errors

**Solutions**:
- Verify `EC2-key.pem` exists in `terraform/` directory
- Check security group allows SSH from Terraform execution environment
- Ensure instance is in a subnet with appropriate routing

#### AMI Baking Fails
**Symptom**: `catalogue.sh` script fails during execution

**Solution**: Check instance has internet connectivity for:
```bash
yum install -y epel-release ansible
ansible-pull -U https://github.com/...
```

#### Targets Unhealthy
**Symptoms**: 
- Instances registered but failing health checks
- ALB returns 503 errors

**Solutions**:
- Verify application is listening on port 8080
- Check `/health` endpoint returns 200 status
- Review application logs on instances
- Confirm security groups allow traffic on port 8080

#### Local-exec Termination Fails
**Symptom**: Temporary instance not terminated after AMI creation

**Solution**: 
- Verify AWS CLI is installed on Jenkins agent
- Check AWS credentials are properly exported
- Ensure IAM permissions include `ec2:TerminateInstances`

## 📁 Repository Structure

```
.
├── Jenkinsfile                 # Pipeline definition
├── README.md                   # This file
├── terraform/
│   ├── catalogue.sh            # AMI provisioning script
│   ├── data.tf                 # Data sources (SSM, AMI)
│   ├── locals.tf               # Local values
│   ├── main.tf                 # Core infrastructure
│   ├── provider.tf             # AWS provider config
│   ├── variables.tf            # Input variables
│   └── EC2-key.pem            # SSH private key (gitignored)
└── terraform.tfstate           # State file (gitignored)
```

## 🔐 Security Notes

- Never commit `EC2-key.pem` to version control
- AWS credentials are injected at runtime via Jenkins
- Private keys and state files are excluded via `.gitignore`
- All instances are deployed in private subnets

## 📝 Notes

- The pipeline uses immutable infrastructure patterns (bake & replace)
- Each deployment creates a new AMI with timestamp
- Auto Scaling Group is replaced on each deployment
- Old AMIs should be cleaned up periodically
- Deregistration delay is set to 60 seconds for graceful shutdown

## 📞 Support

For issues with:
- **Pipeline failures**: Check Jenkins console output
- **Infrastructure issues**: Review Terraform state and AWS Console
- **Application issues**: Contact application development team