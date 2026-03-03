This project demonstrates an event-driven architecture built using core AWS services and deployed through a Bash automation script. The goal of the project is to automatically trigger an email notification whenever a file is uploaded to an Amazon S3 bucket. When an object is created in the S3 bucket, it invokes an AWS Lambda function written in Python. The Lambda function processes the event details and publishes a message to an Amazon SNS topic, which then sends an email notification to the subscribed user. The entire infrastructure setup — including IAM roles, permissions, Lambda deployment, and S3 event configuration — is automated using the AWS CLI within a shell script.

This project was implemented using the following tools and services:

-Amazon S3 – Used to store files and generate object creation events.
-AWS Lambda (Python 3.8) – Executes serverless logic when triggered by S3.
-Amazon SNS – Sends email notifications upon receiving messages from Lambda.
-AWS IAM – Manages roles and permissions between AWS services.
-AWS CLI – Automates infrastructure setup and service configuration.
-Bash Scripting – Orchestrates deployment and integrates AWS CLI commands.
-CloudWatch Logs – Used for monitoring and debugging Lambda execution.
-Ubuntu (Linux environment) – Development and deployment environment.
