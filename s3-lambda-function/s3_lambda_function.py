import json
import boto3

def lambda_handler(event, context):
    try:
        # 1️ Extract S3 bucket and object details
        bucket_name = event['Records'][0]['s3']['bucket']['name']
        object_key = event['Records'][0]['s3']['object']['key']

        print(f"File '{object_key}' uploaded to bucket '{bucket_name}'")

        # 2️ Get Account ID and Region dynamically
        arn_parts = context.invoked_function_arn.split(":")
        region = arn_parts[3]
        account_id = arn_parts[4]

        # 3️ Construct SNS Topic ARN
        topic_name = "s3-lambda-sns-topic"  # Must match your .sh script
        topic_arn = f"arn:aws:sns:{region}:{account_id}:{topic_name}"

        # 4️ Send SNS Notification
        sns_client = boto3.client('sns')

        response = sns_client.publish(
            TopicArn=topic_arn,
            Subject="S3 Object Created - Alert",
            Message=(
                f"Hello,\n\n"
                f"A new file has been uploaded to S3.\n\n"
                f"Bucket: {bucket_name}\n"
                f"File: {object_key}\n"
            )
        )

        print("SNS notification sent successfully.")
        print("SNS Response:", response)

        return {
            "statusCode": 200,
            "body": json.dumps("Notification sent successfully")
        }

    except Exception as e:
        print("Error occurred:", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps("Error processing S3 event")
        }
