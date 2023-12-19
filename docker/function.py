import json
import os
import subprocess
import time
import traceback

import requests

BASE_API_URL = "http://localhost:11434"  # default
SUPPORTED_API_METHODS = ['generate_text', 'generate_embeddings']

# Hacky way to start the Ollama server
if os.system("ps aux | grep ollama | grep -v grep") == 0:
    print("Ollama server is already running")
else:
    print("Starting Ollama server...")
    output = subprocess.Popen(["ollama", "serve"])
    print("Calling lambda test function...")
    # wait 5 seconds for the server to start
    time.sleep(5)


def generate_text(input_text, format=None, options=None, system=None, template=None, context=None, raw=None):
    api_url = BASE_API_URL + "/api/generate"

    # Define the data payload for the API request
    data = {
        "model": os.environ["MODEL_NAME"],
        "prompt": input_text,
        "format": format,
        "options": options,
        "system": system,
        "template": template,
        "context": context,
        "raw": raw,
        "stream": False
    }

    # Making a POST request to the Ollama API
    print(f"Making API request to {api_url} with data {data}")
    response = requests.post(api_url, json=data)

    response_dict = response.json()
    print(f"Response from API: {response_dict}")

    if response.status_code != 200:
        raise ValueError(f"API request failed with status code {response.status_code}: {response.reason}")

    print(f"Generated text: {response_dict['response']}")

    return response_dict


def handle_api(input_text, api_method, api_params):
    if api_method == 'generate_text':
        result = generate_text(input_text, **api_params)
    elif api_method == 'generate_embeddings':
        raise NotImplementedError
    else:
        raise ValueError(f"Unsupported API method: {api_method}")

    return result


def lambda_handler(event, context):
    print(f"Received event {event}")
    print(f"Received context {context}")

    if not os.environ['MODEL_NAME']:
        status_code = 500
        body_dict = {'error': "MODEL_NAME environment variable not set, lambda is invalid"}
    else:
        # Extracting the input text from the Lambda event
        body = event['body']
        if isinstance(body, str):
            body = json.loads(body)

        input_text = body.get('input_text', '')
        api_method = body.get('endpoint', 'generate_text')
        api_params = body.get('params', {})

        try:
            status_code = 200
            response = handle_api(input_text, api_method, api_params)
            body_dict = response
        except Exception as e:
            print("Something went wrong when calling the API")
            print(f"Error: {e}")
            print(traceback.print_exc())

            status_code = 500
            body_dict = {'error': "Something went wrong when calling the API"}

    return {
        'statusCode': status_code,
        'body': json.dumps(body_dict)
    }


def test_lambda_handler():
    test_event = {
        "body": {
            "input_text": "Hello, world!"
        }
    }
    os.environ['MODEL_NAME'] = 'llama2'
    result = lambda_handler(test_event, None)
    print(result)
    assert result['statusCode'] == 200
