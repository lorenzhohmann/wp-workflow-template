#!/bin/bash

echo "Enter a worktitle of the project (e.g. the domain like 'example.com'):"
read worktitle

echo "Enter the theme name of your custom wordpress theme (e.g. oceanwp-child):"
read theme_name

echo "Enter the link of your remote repository (e.g. git@github.com:lorenzhohmann/wp-workflow-template.git)"
read remote_repo

# Setup package.json
sed -i 's/"name": "wp-workflow-template"/"name": "'"$worktitle"'"/' package.json

# Setup .gitignore
sed -i 's/wordpress\/wp-content\/themes\/xxx\//wordpress\/wp-content\/themes\/'"$theme_name"'\//' .gitignore

# Setup .github/ folder
sed -i 's/wordpress\/wp-content\/themes\/xxx\//wordpress\/wp-content\/themes\/'"$theme_name"'\//' .github/workflows/cd.yaml

# Install Node stuff
npm i

# Clear Readme and add default content
echo "# $worktitle" >README.md

# Init empty git repo
sudo rm -rf .git
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin $remote_repo
git push origin main
git branch develop
git checkout develop

# Echo final information
echo "============="
echo "Repo successfully setup!"
echo "=> Follow the next installation step in the README.md file."
