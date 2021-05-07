#!/bin/bash 

while getopts r:u:t:n: flag
do
    case "${flag}" in
        r) url=${OPTARG};;
        t) token=${OPTARG};;
        u) user=${OPTARG};;
        n) name=${OPTARG};;
    esac
done

echo "Url: $url";
echo "Token: $token";
echo "User: $user"
echo "Name: $name"

if [ -z "$url" ] || [ -z "$token" ] || [ -z "$user"] || [ -z "$name" ]
then 
    echo "Invalid arguments"
    exit 1
fi

sudo -i -u $user bash << EOF
echo "In"
mkdir actions-runner && cd actions-runner

curl -o actions-runner-linux-x64-2.278.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.278.0/actions-runner-linux-x64-2.278.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.278.0.tar.gz
./config.sh --url "$url" --token "$token" --name "$name" --work _work --unattended
sudo ./svc.sh install
sudo ./svc.sh start
whoami
EOF
