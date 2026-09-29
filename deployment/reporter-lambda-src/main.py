import os
import boto3
import subprocess
import logging


logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_kosli_api_token():
    secret_arn = os.getenv('KOSLI_API_TOKEN_SECRET_ARN')
    if secret_arn:
        return boto3.client('secretsmanager').get_secret_value(SecretId=secret_arn)['SecretString']
    ssm_parameter_arn = os.getenv('KOSLI_API_TOKEN_SSM_PARAMETER_ARN')
    if ssm_parameter_arn:
        return boto3.client('ssm').get_parameter(Name=ssm_parameter_arn, WithDecryption=True)['Parameter']['Value']
    raise RuntimeError("Neither KOSLI_API_TOKEN_SECRET_ARN nor KOSLI_API_TOKEN_SSM_PARAMETER_ARN is set")

kosli_api_token = get_kosli_api_token()

def lambda_handler(event, context):
    kosli_commands = os.getenv('KOSLI_COMMANDS')
    
    if not kosli_commands:
        logger.error("No commands found in environment variable KOSLI_COMMANDS")
        return {"statusCode": 400, "body": "No commands to execute"}

    # Split the commands into a list
    command_list = kosli_commands.split(';')
    execution_results = []

    # Set up the environment for subprocess
    env = os.environ.copy()
    env['KOSLI_API_TOKEN'] = kosli_api_token

    # Execute each command
    for kosli_command in command_list:
        split_kosli_command = kosli_command.strip().split()
        split_kosli_command[0] = f'/opt/{split_kosli_command[0]}'

        try:
            result = subprocess.run(
                split_kosli_command,
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )

            # Log stdout and stderr
            logger.info(f"Command: {kosli_command}")
            logger.info(result.stdout.decode('utf-8'))
            if len(result.stderr.decode('utf-8')) > 0:
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
