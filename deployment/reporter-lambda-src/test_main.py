import os
import unittest
from unittest.mock import patch, MagicMock

# Set AWS environment variables once for all tests
os.environ['AWS_DEFAULT_REGION'] = 'us-east-1'
os.environ['AWS_ACCESS_KEY_ID'] = 'testing'
os.environ['AWS_SECRET_ACCESS_KEY'] = 'testing'
os.environ['AWS_SECURITY_TOKEN'] = 'testing'
os.environ['AWS_SESSION_TOKEN'] = 'testing'

def make_mock_process(returncode=0, stdout=b'success', stderr=b''):
    mock_process = MagicMock()
    mock_process.returncode = returncode
    mock_process.stdout = stdout
    mock_process.stderr = stderr
    return mock_process

@patch('boto3.client')
@patch('subprocess.run')
class TestLambdaHandler(unittest.TestCase):
    def setUp(self):
        os.environ['KOSLI_API_TOKEN_SSM_PARAMETER_ARN'] = 'mock-arn'

    def tearDown(self):
        os.environ.pop('KOSLI_API_TOKEN_SSM_PARAMETER_ARN', None)
        os.environ.pop('KOSLI_COMMANDS', None)

    def import_lambda(self, mock_boto3):
        # Setup SSM mock
        mock_ssm = MagicMock()
        mock_ssm.get_parameter.return_value = {'Parameter': {'Value': 'mock-token'}}
        mock_boto3.return_value = mock_ssm
        import main
        return main.lambda_handler

    def test_lambda_handler_success(self, mock_subprocess, mock_boto3):
        os.environ['KOSLI_COMMANDS'] = 'kosli report artifact'
        mock_subprocess.return_value = make_mock_process(stdout=b'success output')
        lambda_handler = self.import_lambda(mock_boto3)
        response = lambda_handler({}, {})
        self.assertEqual(response['statusCode'], 200)
        self.assertEqual(response['body'][0]['status'], 'success')
        self.assertEqual(response['body'][0]['output'], 'success output')

    def test_lambda_handler_command_failure(self, mock_subprocess, mock_boto3):
        os.environ['KOSLI_COMMANDS'] = 'kosli invalid command'
        mock_subprocess.return_value = make_mock_process(returncode=1, stderr=b'command not found')
        lambda_handler = self.import_lambda(mock_boto3)
        response = lambda_handler({}, {})
        self.assertEqual(response['body'][0]['status'], 'failed')
        self.assertIn('Error running command', response['body'][0]['error'])

    def test_lambda_handler_multiple_commands(self, mock_subprocess, mock_boto3):
        os.environ['KOSLI_COMMANDS'] = 'kosli command1; kosli command2'
        mock_subprocess.return_value = make_mock_process()
        lambda_handler = self.import_lambda(mock_boto3)
        response = lambda_handler({}, {})
        self.assertEqual(len(response['body']), 2)
        self.assertTrue(all(r['status'] == 'success' for r in response['body']))

    def test_lambda_handler_no_commands(self, mock_subprocess, mock_boto3):
        os.environ['KOSLI_COMMANDS'] = ''
        lambda_handler = self.import_lambda(mock_boto3)
        response = lambda_handler({}, {})
        self.assertEqual(response['statusCode'], 400)
        self.assertEqual(response['body'], 'No commands to execute')

    def test_lambda_handler_subprocess_exception(self, mock_subprocess, mock_boto3):
        os.environ['KOSLI_COMMANDS'] = 'kosli command'
        mock_subprocess.side_effect = Exception('Subprocess error')
        lambda_handler = self.import_lambda(mock_boto3)
        response = lambda_handler({}, {})
        self.assertEqual(response['body'][0]['status'], 'failed')
        self.assertIn('Subprocess error', response['body'][0]['error'])

    def test_lambda_handler_command_with_spaces(self, mock_subprocess, mock_boto3):
        os.environ['KOSLI_COMMANDS'] = 'kosli report artifact --name \"test artifact\"'
        mock_subprocess.return_value = make_mock_process()
        lambda_handler = self.import_lambda(mock_boto3)
        response = lambda_handler({}, {})
        call_args = mock_subprocess.call_args[0][0]
        self.assertEqual(
            call_args[1:], 
            ['report', 'artifact', '--name', '"test', 'artifact"']
        )

if __name__ == '__main__':
    unittest.main() 