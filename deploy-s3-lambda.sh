#!/bin/bash
set -e # Stop on error

# Variables - Update these!
aws_region="us-east-1"
bucket_name="dd-ultimate-bucket-$(date +%s)" # Appended timestamp for uniqueness
lambda_func_name="s3-lambda-function"
role_name="s3-lambda-sns-role"
email_address="furyn448@gmail.com" # Change this to your email
topic_name="s3-lambda-sns-topic"

# 1. Get Account ID
aws_account_id=$(aws sts get-caller-identity --query 'Account' --output text)
echo "Using Account ID: $aws_account_id"

# 2. Create IAM Role (with check)
echo "Creating IAM Role..."
if ! aws iam get-role --role-name "$role_name" >/dev/null 2>&1; then
    aws iam create-role --role-name "$role_name" --assume-role-policy-document '{
      "Version": "2012-10-17",
      "Statement": [{
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": { "Service": "lambda.amazonaws.com" }
      }]
    }'
    aws iam attach-role-policy --role-name "$role_name" --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
    aws iam attach-role-policy --role-name "$role_name" --policy-arn arn:aws:iam::aws:policy/AmazonSNSFullAccess
    sleep 10 # Wait for IAM replication
else
    echo "Role $role_name already exists."
fi

# 3. Create S3 Bucket
echo "Creating Bucket..."
aws s3api create-bucket --bucket "$bucket_name" --region "$aws_region" || echo "Bucket exists."

# 4. Create SNS Topic & Subscription
echo "Setting up SNS..."
topic_arn=$(aws sns create-topic --name "$topic_name" --query 'TopicArn' --output text)
aws sns subscribe --topic-arn "$topic_arn" --protocol email --notification-endpoint "$email_address"
echo "Check your email ($email_address) and click 'Confirm Subscription' now!"

# 5. Package and Create/Update Lambda
echo "Deploying Lambda..."
zip -rj s3-lambda-function.zip ./s3-lambda-function/ # 'j' flattens the path so handler works
if aws lambda get-function --function-name "$lambda_func_name" >/dev/null 2>&1; then
    aws lambda update-function-code --function-name "$lambda_func_name" --zip-file "fileb://s3-lambda-function.zip"
else
    aws lambda create-function \
      --function-name "$lambda_func_name" \
      --runtime "python3.8" \
      --handler "s3_lambda_function.lambda_handler" \
      --role "arn:aws:iam::$aws_account_id:role/$role_name" \
      --zip-file "fileb://s3-lambda-function.zip"
fi

# 🔥 ADD THIS HERE
aws lambda wait function-active --function-name "$lambda_func_name"

# 6. Add S3 Permissions to Lambda (Allow S3 to call Lambda)
aws lambda add-permission \
  --function-name "$lambda_func_name" \
  --statement-id "s3-invoke-$(date +%s)" \
  --action "lambda:InvokeFunction" \
  --principal s3.amazonaws.com \
  --source-arn "arn:aws:s3:::$bucket_name" || true

# 7. Configure S3 Event Notification
lambda_arn="arn:aws:lambda:$aws_region:$aws_account_id:function:$lambda_func_name"
aws s3api put-bucket-notification-configuration \
  --bucket "$bucket_name" \
  --notification-configuration '{
    "LambdaFunctionConfigurations": [{
        "LambdaFunctionArn": "'"$lambda_arn"'",
        "Events": ["s3:ObjectCreated:*"]
    }]
}'

# 8. TRIGGER THE FLOW (Last Step)
echo "Uploading file to trigger Lambda..."
echo "Hello World" > test_file.txt
aws s3 cp test_file.txt "s3://$bucket_name/test_file.txt"

echo "Flow complete! If you confirmed the email, you should receive a notification shortly."
