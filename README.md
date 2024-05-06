# AWS LakeFormation with Glue
This Terraform project manages a variety of AWS resources, including S3 buckets, AWS Glue configurations, and Lake Formation settings. It's designed to ensure that only the correct roles have query access to these resources.
## Project Structure
```plaintext
├── data.tf
├── glue.tf
├── lakeformation.tf
├── outputs.tf
├── plan.out
├── s3.tf
├── terraform.tfvars
├── variables.tf
└── versions.tf
```
## Prerequisites
Before you can use this Terraform project, you'll need to have the following installed:
- Terraform (v1.0 or higher recommended)
- AWS CLI
- An AWS account with the necessary permissions
## Installation
To install and start using this Terraform project, follow these steps:
1. **Clone the repository:**
    ```bash
    git clone https://github.com/semperfitodd/aws_lakeformation.git
    cd aws_lakeformation
    ```
2. **Initialize Terraform:**
    ```bash
    terraform init
    ```
    This will initialize a Terraform working directory by downloading and configuring the necessary providers.
3. **Create a Terraform plan:**
    ```bash
    terraform plan -out=plan.out
    ```
    This will create an execution plan, which lets you preview the changes that Terraform plans to make to your infrastructure.
4. **Apply the Terraform plan:**
   ```bash
   terraform apply plan.out
   ```
    This command applies the changes required to reach the desired state of the configuration.
## Run the glue crawler
This is running on the `commoncrawl` S3 bucket which is huge.

![bucket_size.png](images%2Fbucket_size.png)

See the documentation for the data [here](https://registry.opendata.aws/commoncrawl/).

This job is set on a cron to run once a month, but you can start it manually in the AWS console.

![completed_glue_job.png](images%2Fcompleted_glue_job.png)
## Testing permissions
To test the configuration and ensure that only the correct roles can query while others cannot, use the AWS CLI:
```bash
aws athena start-query-execution \                            [10:09:39]
    --query-string "SELECT * FROM data_50600a86b68063ce3940961a3222e0bf LIMIT 10;" \
    --query-execution-context Database=aws_lakeformation_poc_dqbn \
    --result-configuration OutputLocation=s3://aws-lakeformation-poc-dqbn/ \
    --profile lfrole # this is the role that has access through TF
    
{
    "QueryExecutionId": "3faf9805-4efc-43f7-88c5-b11d51b746ea"
}
```
Let's see if it succeeded
```bash
aws athena get-query-execution \
    --output text --query 'QueryExecution.Status.State' \
    --query-execution-id 3faf9805-4efc-43f7-88c5-b11d51b746ea
SUCCEEDED
```
Let's see our output
```bash
aws s3 cp s3://aws-lakeformation-poc-dqbn/3faf9805-4efc-43f7-88c5-b11d51b746ea.csv ./temp/output.csv

cat temp/output.csv     
                                                            [10:15:56]
"col0","col1","col2","col3","col4","col5","col6","col7
```
What if we use a different role? The role we are using has `AdministratorAccess`
```bash
aws athena start-query-execution \                            [10:09:39]
    --query-string "SELECT * FROM data_50600a86b68063ce3940961a3222e0bf LIMIT 10;" \
    --query-execution-context Database=aws_lakeformation_poc_dqbn \
    --result-configuration OutputLocation=s3://aws-lakeformation-poc-dqbn/ \
    --profile lftest # this is a basic administrator role
    
{
    "QueryExecutionId": "a07eda91-43fa-4ed6-a7cc-acd93b58dcb3"
}
```
Check the execution
```bash
aws athena get-query-execution \                                                    [10:16:04]
    --output text --query 'QueryExecution.Status.State' \
    --query-execution-id a07eda91-43fa-4ed6-a7cc-acd93b58dcb3
FAILED
```
Since there are no granular permissions in lakeformation, the query failed.
