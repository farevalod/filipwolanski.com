#!/bin/bash

set -e -x

sudo mkdir -p /opt/fev
sudo chmod 777 /opt/fev

aws s3 cp s3://fevocabulary/models /opt/fev/models --recursive
aws s3 cp s3://fevocabulary/data/texts.edn /opt/fev/texts.edn

# runs upon shutdown
cat > /mnt/var/lib/instance-controller/public/shutdown-actions/term.sh << 'EOF'

if [ -f /opt/fev/example.json ]; then
  aws s3 cp /opt/fev/example.json s3://fevocabulary/data/results/example.json
fi

if [ -f /opt/fev/unique.json ]; then
  aws s3 cp /opt/fev/unique.json s3://fevocabulary/data/results/unique.json
fi

if [ -f /opt/fev/words.json ]; then
  aws s3 cp /opt/fev/words.json s3://fevocabulary/data/results/words.json
fi

EOF
