## Introduction

## Getting started
### 1. Setup AWS credentials
```bash
aws configure
```

### 2. Make Docker available to user
####  2.1 Linux
```bash
sudo usermod -aG docker $USER
sudo systemctl restart docker
# you may need to log out and login
```
####  2.2 MacOs
```bash
sudo chown -R $(whoami):staff /Users/$(whoami)/.docker
```

### 3 Push ECR image
```bash
# Fix some file permissions 
chmod +x ./scripts/setup.sh
chmod +x ./scripts/push_ecr.sh

# Run the main setup script
./scripts/setup.sh 

# check cloudformation stack status
#mkdir ./logs
#aws cloudformation describe-stack-events --stack-name ollama-llama2-serverless > ./stack_events.json


```


