# HHN AWS Cloud Terraform Project

This project demonstrates the deployment of a simple web application using AWS services and Terraform. The web application is a Flask-based API that is containerized using Docker and deployed using AWS App Runner. The static content is hosted on an S3 bucket.

## Project Structure

- `webapp/index.html`: The main HTML file for the web application.
- `variables.tf`: Terraform variables configuration.
- `providers.tf`: Terraform providers configuration.
- `main.tf`: Main Terraform configuration file.
- `Dockerfile`: Dockerfile to containerize the Flask application.
- `app.py`: Flask application code.
- `.gitignore`: Git ignore file to exclude certain files from version control.

## Prerequisites

- AWS CLI configured with appropriate permissions.
- Terraform installed.
- Docker installed.

## Setup Instructions

1. **Clone the repository:**
   ```sh
   git clone <repository-url>
   cd HHN-AWS-Cloud-Terraform
   ```

2. **Set Terraform variables:**
    - Create the `variables.tf` file with appropriate values given below.
    - The `region` variable should be set to the AWS region where the resources will be deployed.
    - The `bucket_name` variable should be set to a unique name for the S3 bucket.
    - The `bucket_acl` variable should be set to the ACL for the S3 bucket.
    - The `repo_name` variable should be set to the name of the ECR repository.

3. **Initialize Terraform:**
   ```sh
   terraform init
   ```

4. **Apply Terraform configuration:**
   ```sh
   terraform apply -auto-approve
   ```

5. **Access the web application:**
   - The URL of the S3 bucket hosting the static content will be output by Terraform.
   - The API endpoint URL will also be output by Terraform.

6. **Destroy the resources:**
   ```sh
    terraform destroy -auto-approve
    ```

## Outputs

- `bucket_url`: The URL of the S3 bucket hosting the static content.
- `service_url`: The URL of the deployed API service.