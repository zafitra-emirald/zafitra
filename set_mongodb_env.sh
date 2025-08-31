#!/bin/bash
# Script to set correct MongoDB environment variables for labsos-v1

export MONGODB_USERNAME="zafitraem_db_user"
export MONGODB_PASSWORD="WL7Ya3Q8aOgwwPvM"
export MONGODB_HOST="cluster0.ccqv2dn.mongodb.net"
export MONGODB_DATABASE="labsos-v1"

echo "MongoDB environment variables updated:"
echo "MONGODB_USERNAME=$MONGODB_USERNAME"
echo "MONGODB_PASSWORD=$MONGODB_PASSWORD"
echo "MONGODB_HOST=$MONGODB_HOST"
echo "MONGODB_DATABASE=$MONGODB_DATABASE"
echo ""
echo "Run this script with: source set_mongodb_env.sh"
echo "Or add these exports to your ~/.bashrc or ~/.profile for permanent changes"