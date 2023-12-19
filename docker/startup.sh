#!/bin/sh
# Start the server
/bin/ollama serve &

# Check if argument passed, otherwise error
if [ -z "$1" ]; then
    echo "No argument supplied. Please pass the model name."
    exit 1
fi

# Wait a bit for the server to start up
sleep 10

# Pull model
ollama pull "$1"