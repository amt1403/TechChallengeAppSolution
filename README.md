# Servian DevOps Tech Challenge - Tech Challenge App

## Overview

This is a solution to Servian DevOps Tech challenge. It uses a simple application to help measure a candidate's technical capability and fit with Servian. The application itself is a simple GTD Golang application that is backed by a Postgres database.

Servian provides the Tech Challenge to potential candidates, which focuses on deploying this application into a cloud environment of choice.

More details about the application can be found in the [document folder](doc/readme.md)

## Prerequisites
- AWS account
- Install and configure terraform
- Create AWS ACCESS KEY and AWS SECRET KEY

## How to provision the solution and deploy the application.
- Clone the repo

### Clone this repo
```sh
git clone https://github.com/Abdullah-Altahhan/TechChallengeAppSolution.git
```
- Export the AWS ACCESS KEY and AWS SECRET KEY to environment variables
- Run Terraform init, and Terraform plan, Terraform plan

### Usage
```terraform init
terraform apply
```

## High level architecture
- Solution will be deployed in sydney region.
- ECS cluster with fargate is used to deploy and run the container for serverless architecture.
- RDS for PostgreSQL is used for serverless architecture.
- ELB is deployed in public subnet, while ECS and RDS are deployed in private subnets.
- Autoscaling is configured for ECS using memory and cpu utilization thresholds.

## High level description of improvements (if any).
- Encryption in transit and at rest is considered out of scope for this simplicity. KMS and HTTP could be added later.
- Naming considered multi-evironment deployment, naming standardization could be improved.
- 

## CICD
- CICD can be done to automate the terraform deployment to multiple environments and complete testing before prod deployment
- AWS pipeline/ Codefresh/ Bitbucket pipeline could be used to automate the pipeline. For this project, the pipeline could be triggered from a commit to master branch. The pipeline could consist of view steps:
    - Cloning the repo
    - Use terraform docker image to run terraform init
    - Use terraform docker image to run terraform apply
    - Use aws cli docker image to run testing scripts




