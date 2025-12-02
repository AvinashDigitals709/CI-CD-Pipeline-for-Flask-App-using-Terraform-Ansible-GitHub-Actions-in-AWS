# 🚀 CI/CD Pipeline for Flask App using Terraform, Ansible, & GitHub Actions in AWS

This project provides a complete, automated Continuous Integration and Continuous Deployment (CI/CD) pipeline for deploying a Flask web application onto AWS EC2. The workflow leverages a powerful combination of Terraform for infrastructure provisioning, GitHub Actions for orchestration, and Ansible for application configuration and deployment.

## 🏗️ Architecture and Workflow

The architecture follows a standard GitOps approach, where every code change triggers an automated, end-to-end workflow, ensuring consistent and reproducible deployments.

### Deployment Flow Summary

1. A developer pushes code to the main branch on GitHub.
2. GitHub Actions initiates the pipeline.
3. Terraform provisions the necessary AWS infrastructure (EC2, Security Group, S3 backend).
4. Ansible securely connects to the new EC2 instance via SSH and executes the deployment.
5. Ansible installs dependencies (Gunicorn, NGINX, Python packages) and configures the Flask application.
6. The application becomes accessible via the EC2 Public IP.

## 📁 Project Repository Structure

Your repository must adhere to the following structure for the pipeline to function correctly:

```
.
├── app/
│   ├── static/
│   ├── templates/
│   ├── application.py
│   ├── clothing.png
│   ├── data.db
│   ├── requirements.txt
│   └── wsgi.py
├── ansible/
│   └── deploy.yml
├── terraform/
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── provider.tf
│   └── variables.tf
└── .github/workflows/
    └── ci-cd.yml
```

## 🛠️ Setup Instructions

### 1. Prerequisites

#### AWS Requirements
- AWS Account.
- IAM User with the following permissions:
  - AmazonEC2FullAccess
  - AmazonS3FullAccess
  - IAMReadOnlyAccess
  - AmazonVPCReadOnlyAccess
- EC2 Key Pair (Manual Step):
  - Create a new EC2 Key Pair in the AWS Console (e.g., named `ci-cd`).
  - Download the `.pem` file.
  - The content of this `.pem` file is required for the pipeline's SSH connection.

#### GitHub Secrets Configuration

The pipeline relies on these secrets for authentication and secure connectivity. Go to GitHub Repo → Settings → Secrets → Actions and add the following:

| Secret Name          | Description                                      |
|----------------------|--------------------------------------------------|
| AWS_ACCESS_KEY_ID    | IAM user access key                              |
| AWS_SECRET_ACCESS_KEY| IAM user secret key                              |
| SSH_PRIVATE_KEY      | The raw content of the downloaded .pem private key file |

### 2. Configure Terraform Variables

Update `terraform/variables.tf` to match your environment:

```terraform
variable "project_name" {
  default = "flask-ecommerce"
}

variable "key_name" {
  # MUST match the name of the Key Pair created in the AWS console
  default = "ci-cd"
}
```

### 3. SSH Private Key Handling

The `ci-cd.yml` workflow securely handles the private key for Ansible connectivity:

```bash
echo "${{ secrets.SSH_PRIVATE_KEY }}" > ssh_key.pem
chmod 600 ssh_key.pem
```

This ensures the private key is available to the runner as a file (`ssh_key.pem`) with restricted permissions for Ansible to use.

## ⚙️ CI/CD Pipeline Workflow Breakdown

The deployment is executed in three logical phases by the GitHub Actions workflow.

### Phase 1: Infrastructure Provisioning (Terraform)
- Checkout Code and Install Dependencies.
- Configure AWS Credentials.
- Auto-Create S3 Backend Bucket: Creates the remote state bucket before `terraform init` (Crucial Fix).
- Terraform Init / Apply: Provisions the EC2 instance, Security Group, and associated resources.
- Output Public IP: Captures the newly provisioned EC2 Public IP address.

### Phase 2: Deployment Setup (Connecting Ansible)
- Check SSH Availability: Implements a wait/retry loop to ensure the EC2 instance is fully booted and the SSH service is ready.
- Write `ssh_key.pem`: Creates the private key file on the runner.
- Dynamic Inventory Creation: Generates the temporary `inventory.ini` file using the captured EC2 IP:

  ```ini
  [flask]
  <EC2_IP> ansible_user=ubuntu ansible_ssh_private_key_file=ssh_key.pem
  ```

- Run Ansible Deployment: Executes the final playbook command:

  ```bash
  ansible-playbook -i inventory.ini ansible/deploy.yml
  ```

### Phase 3: Ansible Deployment Tasks (`ansible/deploy.yml`)

The playbook performs the following setup on the remote EC2 instance:
- Install System Dependencies: Installs Python3, Pip, Virtualenv, and NGINX.
- Setup Flask Application: Creates `/var/www/flaskapp`, copies code, and installs Python packages.
- Configure Gunicorn: Creates and starts a systemd service for Gunicorn.
- Configure NGINX Reverse Proxy: Sets up NGINX to proxy traffic from port 80 to the Gunicorn socket.

## ✅ Deployment Complete – Access Application

Once the pipeline finishes, your Flask application is live and accessible:

```
http://<EC2_PUBLIC_IP>
```

## ❌ Rollback / Destroy Infrastructure

To completely dismantle all AWS resources provisioned by Terraform, run the following commands from your local machine:

```bash
cd terraform
terraform destroy
```

## 💡 Challenges and Learnings

| Challenge                          | Solution                                                                 |
|------------------------------------|--------------------------------------------------------------------------|
| Terraform Could Not Create S3 Backend | S3 bucket creation was implemented as a preceding step in GitHub Actions before `terraform init`. |
| EC2 IP Extraction Failed in Pipeline | Used a clean, dedicated Terraform output variable for the EC2 Public IP, avoiding complex parsing logic. |
| SSH Host Key Verification Errors   | Configured the Ansible connection to disable StrictHostKeyChecking to avoid validation failures on new hosts. |
| SSH Not Ready After EC2 Creation   | Implemented a wait/retry loop to ensure the SSH service was fully active before running Ansible. |
