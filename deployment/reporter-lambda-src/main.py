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
    kosli_commands = os.getenv('KOSLI_COMMANDS')
    
    if not kosli_commands:
        logger.error("No commands found in environment variable KOSLI_COMMANDS")
        return {"statusCode": 400, "body": "No commands to execute"}

    # Split the commands into a list
    command_list = kosli_commands.split(';')
    execution_results = []

    # Execute each command
    for kosli_command in command_list:
        split_kosli_command = kosli_command.strip().split()
        split_kosli_command[0] = f'./{split_kosli_command[0]}'

        try:
            result = subprocess.run(
                split_kosli_command + ['--api-token', kosli_api_token],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )

            # Log stdout and stderr
            logger.info(f"Command: {kosli_command}")
            logger.info(result.stdout.decode('utf-8'))
            logger.error(result.stderr.decode('utf-8'))

            # Append success or failure to results list
            if result.returncode != 0:
                error_message = f"Error running command: {kosli_command}, stderr: {result.stderr.decode('utf-8')}"
                logger.error(error_message)
                execution_results.append({"command": kosli_command, "status": "failed", "error": error_message})
            else:
                execution_results.append({"command": kosli_command, "status": "success", "output": result.stdout.decode('utf-8')})

        except Exception as e:
            error_message = f"Exception running command: {kosli_command}, Error: {e}"
            logger.error(error_message)
            execution_results.append({"command": kosli_command, "status": "failed", "error": error_message})

    # Return a summary of all command executions
    return {"statusCode": 200, "body": execution_results}