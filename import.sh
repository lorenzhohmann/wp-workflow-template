#!/bin/bash

#########################
## DON'T USE! STILL UNDER DEVELOPMENT! ##
#########################

### SETTINGS ###
local_path="wordpress"
################

#########################
#########################
####### WORKFLOW ########
#########################
#########################

# Grep hostname
while true; do
  echo "Enter the live hostname (format: 'https://domain.tld'):"
  read hostname

  if [ -z "$hostname" ]; then
    echo "[ERR] Hostname cannot be empty."
  else
    break
  fi
done

# Grep sql file name
for file in "$local_path"/*.sql; do
  if [[ -f "$file" ]]; then
    read -p "> $file: Do you want to import this file into the database? (y/n): " choice

    if [ "$choice" = "y" ]; then
      sql_file="$file"
      echo "Selected file: $sql_file"
      break
    fi
  fi
done

if [ -n "$sql_file" ]; then
  echo "You selected: $sql_file"
else
  echo "[ERR] No .sql file found. Exit."
  exit 1
fi

# Read database connection data from wp-config.php
db_name=$(sed -n "s/define( *'DB_NAME', *'\([^']*\)'.*/\1/p" $local_path/wp-config.php)
db_host=$(sed -n "s/define( *'DB_HOST', *'\([^']*\)'.*/\1/p" $local_path/wp-config.php)
db_password=$(sed -n "s/define( *'DB_PASSWORD', *'\([^']*\)'.*/\1/p" $local_path/wp-config.php)
db_user=$(sed -n "s/define( *'DB_USER', *'\([^']*\)'.*/\1/p" $local_path/wp-config.php)

# Setup .env file
cp .env.template .env # REPLACE WITH mv
sed -i "s/MYSQL_DATABASE=.*/MYSQL_DATABASE=$db_name/" .env
sed -i "s/MYSQL_USER=.*/MYSQL_USER=$db_user/" .env
sed -i "s/MYSQL_PASSWORD=.*/MYSQL_PASSWORD=$db_password/" .env

for dir in "$local_path"/wp-content/themes/*/; do
  if [[ -d "$dir" ]]; then
    read -p "> $dir: Is this the theme that should be used? (y/n): " choice

    if [ "$choice" = "y" ]; then
      theme_path="$dir"
      echo "Selected directory: $theme_path"
      break
    fi
  fi
done

# Get and set theme path
if [ -n "$theme_path" ]; then
  echo "You selected: $theme_path"
  sed -i "s/THEME_DIRECTORY=.*/THEME_DIRECTORY=$theme_path" .env
else
  echo "[ERR] No theme selected. Exit."
  exit 1
fi

# Start Docker Compose Daemon
docker compose up -d

# Replace hostname in SQL file
sed -i "s#$hostname#http://localhost#g" $sql_file

# Import SQL file into database
echo "[INFO] Waiting 10 seconds before importing SQL file..."
sleep 10
mysql -h 127.0.0.1 -P 3306 -u $db_user -p$db_password $db_name <$sql_file
echo "[INFO] SQL file $sql_file successfully imported."

# Update wp-config.php with database host
sed -i "s/define( *'DB_HOST', *'\([^']*\)'.*/define( 'DB_HOST', 'database' );/g" "$local_path/wp-config.php"

echo "<<<<<<>>>>>>"
echo "Make sure that you've ran this command in WSL2 once:"
echo "npm install -g eslint eslint-config-airbnb eslint-plugin-prettier eslint-config-airbnb-base eslint-config-prettier prettier eslint-plugin-import"
echo ""
echo "Website: http://localhost/"
echo "phpmyadmin: http://localhost:8081/"
echo "  Username: $db_user"
echo "  Password: $db_password"
