import os
import boto3
import subprocess
import logging


logger = logging.getLogger()
logger.setLevel(logging.INFO)

ssm_client = boto3.client('ssm')

ssm_parameter_name = os.getenv('KOSLI_API_TOKEN_SSM_PARAMETER_NAME')

if not ssm_parameter_name:
    logger.error("Environment variable KOSLI_API_TOKEN_SSM_PARAMETER_NAME is not set")

try:
    response = ssm_client.get_parameter(Name=ssm_parameter_name, WithDecryption=True)
    kosli_api_token = response['Parameter']['Value']
except Exception as e:
    logger.error(f"Error retrieving SSM parameter: {e}")

def lambda_handler(event, context):
    kosli_command = os.getenv('KOSLI_COMMAND')

    split_kosli_command = kosli_command.split()
    split_kosli_command[0] = f'./{split_kosli_command[0]}'

    try:
        result = subprocess.run(split_kosli_command + ['--api-token', kosli_api_token], 
                                stdout=subprocess.PIPE, 
                                stderr=subprocess.PIPE)

        # Log stdout and stderr
        logger.info(result.stdout.decode('utf-8'))
        logger.error(result.stderr.decode('utf-8'))

        # Check if the command was successful
        if result.returncode != 0:
            return {"statusCode": 500, "body": f"Error running kosli command: {result.stderr.decode('utf-8')}"}
        
        return {"statusCode": 200, "body": f"Kosli command executed successfully: {result.stdout.decode('utf-8')}"}
    
    except Exception as e:
        logger.error(f"Error running kosli command: {e}")
        return {"statusCode": 500, "body": f"Error running kosli command: {e}"}