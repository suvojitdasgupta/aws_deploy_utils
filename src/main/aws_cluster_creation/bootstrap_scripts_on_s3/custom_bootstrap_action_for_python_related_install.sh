#!/bin/bash

# python3 install

echo -e "==== Custom bootstrap action for python3 install - begins === \n\n"
echo -e "Executing , sudo yum install -y python34 .. \n"

sudo yum install -y python34

echo -e "\n=== Custom bootstrap action for python3 install - Complete === \n\n\n"


# For hdfs dashboard util related multi-threading

echo -e "==== Custom bootstrap action for 'pip futures' install - begins === \n\n"
echo -e "Executing , sudo pip install futures .. \n"

sudo pip install futures

echo -e "\n=== Custom bootstrap action for 'pip futures' install - Complete === \n\n\n"


# For hdfs dashboard util related hdfs connector

echo -e "==== Custom bootstrap action for 'pip snakebite' install - begins === \n\n"
echo -e "Executing , sudo pip install snakebite .. \n"

sudo pip install snakebite

echo -e "\n=== Custom bootstrap action for 'pip snakebite' install - Complete === \n\n\n"
