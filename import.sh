#!/bin/bash

### SETTINGS ###
local_path="wordpress"
################

#########################
#########################
####### FUNCTIONS #######
#########################
#########################

# Import local tgz file
import_local() {
  # Grep local tgz file
  for file in "$local_path"/*.tgz; do
    if [[ -f "$file" ]]; then
      read -p "> $file: Do you want to import this file? (y/n): " choice

      if [ "$choice" = "y" ]; then
        tgz_file="$file"
        echo "Selected file: $tgz_file"
        break
      fi
    fi
  done

  if [ -n "$tgz_file" ]; then
    echo "You selected: $tgz_file"
  else
    echo "[ERR] No .tgz file found. Exit."
    exit 1
  fi

  # Extract tgz file
  tar -xzf "$tgz_file" -C "$local_path"

  # Remove tgz file
  rm "$tgz_file"
}

# Sync files from remote server
import_remote() {
  # read hostname and user of remote server
  echo "Enter the connection data of the remote server (format: 'user@host')"
  read remote_server

  # read remote directory
  echo "Enter the remote directory (e.g. '/var/www/vhosts/example.com/httpdocs')"
  read remote_directory
  remote_directory="$remote_directory/*"

  # Use rsync to sync the directories
  rsync -avz --delete --progress --exclude=".ftp-deploy-sync-state.json" "$remote_server:$remote_directory" "$local_path"

  # check if rsync was successful
  if [ $? -eq 0 ]; then
    echo "Sync completed successfully."
  else
    echo "Sync failed with error code $?. Exit."
    exit 1
  fi
}

# Import SQL file into database
import_sql() {
  # Replace hostname in SQL file
  sed -i "s#$hostname#http://localhost#g" $sql_file

  # Import SQL file into database
  echo "[INFO] Waiting 10 seconds before importing SQL file..."
  sleep 10
  mysql -h 127.0.0.1 -P 3306 -u $db_user -p$db_password $db_name <$sql_file
  echo "[INFO] SQL file $sql_file successfully imported."
}

#########################
#########################
####### WORKFLOW ########
#########################
#########################

# Ask to import local tgz file or to sync with remote server and call the specific functions
while true; do
  echo "Do you want to import a local tgz file or sync with a remote server? (local/remote):"
  read choice

  if [ "$choice" = "local" ]; then
    import_local
    break
  elif [ "$choice" = "remote" ]; then
    import_remote
    break
  else
    echo "[ERR] Invalid choice. Please try again."
  fi
done

# Read database connection data from wp-config.php
db_name=$(sed -n "s/define( *'DB_NAME', *'\([^']*\)'.*/\1/p" $local_path/wp-config.php)
db_host=$(sed -n "s/define( *'DB_HOST', *'\([^']*\)'.*/\1/p" $local_path/wp-config.php)
db_password=$(sed -n "s/define( *'DB_PASSWORD', *'\([^']*\)'.*/\1/p" $local_path/wp-config.php)
db_user=$(sed -n "s/define( *'DB_USER', *'\([^']*\)'.*/\1/p" $local_path/wp-config.php)

# Setup .env file
rm .env
cp .env.template .env
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
  import_sql
else
  echo "[ERR] No .sql file found. Skip."
fi

# Start Docker Compose Daemon
docker compose down
docker compose up -d

# Update wp-config.php with database host
sed -i "s/define( *'DB_HOST', *'\([^']*\)'.*/define( 'DB_HOST', 'database' );/g" "$local_path/wp-config.php"

echo "<<<<<<>>>>>>"
echo "Website: http://localhost/"
echo "phpmyadmin: http://localhost:8081/"
echo "  Username: $db_user"
echo "  Password: $db_password"
echo ""
if [ -z "$sql_file" ]; then
  echo "Warning: No SQL file was imported. Do it manually!"
fi
