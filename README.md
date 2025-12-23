## 07-catalogue-deploy (Catalogue deployment)

This repository contains the **deployment pipeline and Terraform** for rolling out the Catalogue service on AWS.

### Repo responsibility (DevOps view)
- Accept an application `version` (from the build pipeline).
- Run Terraform to bake an AMI for that version.
- Deploy/refresh an Auto Scaling Group behind an ALB Target Group + listener rule.

This repo does **not** build the Node.js app and does **not** publish to Nexus. Those happen in the app repo.

### CI/CD (Jenkins) — deploy pipeline contract
Pipeline: [Jenkinsfile](Jenkinsfile)

#### Required input
- `version` (string): application version to deploy.
	- Passed to Terraform as `-var="app_version=${params.version}"`.

#### Jenkins agent requirements
The Jenkins node labeled `AGENT-1` must have:
- `terraform` CLI
- `aws` CLI (required by Terraform `local-exec` that terminates the bake instance)
- Bash/sh compatible shell (pipeline uses `sh` steps)

#### Jenkins credentials
- `aws-creds` (Username/Password credential)
	- Mapped to `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
	- Region is hard-coded in pipeline to `ap-south-1`

#### Pipeline stages (as implemented)
- **Deploy**: echoes `params.version`
- **Init**: `terraform init -reconfigure` in `terraform/`
- **Approve**: manual gate, limited to submitters `alice,bob`
- **Plan**: `terraform plan -var="app_version=${params.version}"`
- **Apply**: `terraform apply -var="app_version=${params.version}" -auto-approve`

### Terraform: what gets created
Terraform lives under [terraform/](terraform/).

#### High-level flow
1. **Bake AMI**
	 - Launch a temporary EC2 instance from a base AlmaLinux AMI ([terraform/data.tf](terraform/data.tf)).
	 - SSH into it, upload and run [terraform/catalogue.sh](terraform/catalogue.sh) with `app_version`.
	 - Stop instance and create an AMI from it.
	 - Terminate the temporary instance.
2. **Deploy compute + traffic**
	 - Create an ALB Target Group on `HTTP:8080` with health check `GET /health`.
	 - Create a Launch Template using the baked AMI.
	 - Create/replace an Auto Scaling Group (min 2, desired 2, max 5) in private subnets.
	 - Add a listener rule that forwards host-based traffic to the target group.

#### Health check contract
- Target group health check: path `/health`, port `8080` ([terraform/main.tf](terraform/main.tf))
- The app must return 2xx for `/health` to be considered healthy.

### Inputs and defaults
Variables: [terraform/variables.tf](terraform/variables.tf)

- `app_version`: **overridden by Jenkins** (default in code is `100.100.100`)
- `env`: default `dev`
- `domain_name`: default `stallions.space`
- `project_name`: default `roboshop`
- `common_tags.component`: default `catalogue`

### External prerequisites (must exist before running)

#### SSM Parameter Store keys
Terraform reads these SSM parameters (names are derived from variables):
- `/${project_name}/${env}/vpc_id`
- `/${project_name}/${env}/catalogue_sg_id`
- `/${project_name}/${env}/private_subnet_ids` (comma-separated subnet IDs)
- `/${project_name}/${env}/app_alb_listener_arn`

Defined in [terraform/data.tf](terraform/data.tf).

#### SSH requirements for AMI bake
- EC2 instance uses `key_name = "EC2-key"` ([terraform/main.tf](terraform/main.tf))
- Terraform SSH uses `private_key = file("EC2-key.pem")` (expects the PEM in the terraform working dir)

#### Network egress for bake step
The bake instance must be able to reach:
- OS package repos (yum)
- GitHub (to run `ansible-pull` from a public repo)

### How the version is applied on instances
The Jenkins `version` parameter becomes Terraform `app_version`, which is passed into [terraform/catalogue.sh](terraform/catalogue.sh) as `$1`, then into `ansible-pull` as `-e APP_VERSION=<version>`.

### Routing / DNS expectation
Listener rule routes based on host header:
- `${component}.app-${env}.${domain_name}`
	- With defaults: `catalogue.app-dev.stallions.space`

Implemented in [terraform/main.tf](terraform/main.tf).

### Manual run (without Jenkins)
From the `terraform/` directory:
- `terraform init -reconfigure`
- `terraform plan -var="app_version=<version>"`
- `terraform apply -var="app_version=<version>" -auto-approve`

### Troubleshooting (common)
- **Plan fails on SSM reads**: missing/incorrect SSM parameter names for the selected `project_name`/`env`.
- **Provisioner SSH fails**: key pair name and PEM mismatch, instance not reachable in private subnet, or security group missing SSH access.
- **AMI bake fails in catalogue.sh**: instance lacks egress to yum/GitHub.
- **Local-exec terminate fails**: `aws` CLI not installed on the Jenkins agent or creds/region not exported.
- **Targets unhealthy**: app not listening on 8080 or `/health` not returning 2xx.
