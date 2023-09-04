#!/bin/bash

#########################
## DON'T USE! STILL UNDER DEVELOPMENT! ##
#########################

### SETTINGS ###
local_path="wordpress"
################

#########################
#########################
####### FUNCTIONS #######
#########################
#########################

# Import a local tgz file
import_tgz() {
  # Grep tgz file name
  while true; do
    echo "Enter the tgz file:"
    read tgz_file

    if [ -z "$name" ]; then
      echo "[ERR] tgz file cannot be empty."
    else
      break
    fi
  done

  tar -xvzf $tgz_file $local_path
}

# create tgz on remote, download and extract it
download_remote_tgz() {
  # TODO
}

# Download directory from remote server
sync_with_remote() {
  domain=$(echo "$hostname" | sed -E 's~https?://([^/]+).*~\1~')
  remote_server_default_path="/var/www/vhosts/$domain/httpdocs"
  echo "Enter installation path from remote host (leave empty to use this path: $remote_server_default_path):"
  read remote_path

  if [[ -z "$remote_path" ]]; then
    remote_path=$remote_server_default_path
  fi

  # Sync from remote => local (download)
  # rsync -avhz --progress --delete-after user@server.com:"$remote_path/*" "$local_path"

  echo "[INFO] Successfully synced remote ($remote_path) with local folder ($local_path/)"
}

# Show the menu to choose between sync and import local tgz
show_choose_remote_sync_local_tgz() {
  echo "Choose an option:"
  echo "1. Sync from remote"
  echo "2. Download whole page from remote"
  echo "3. Import local tgz file"
  echo "0. Exit"
}

# Read the input for sync or import local tgz
read_choice_remote_sync_local_tgz() {
  read -p "Enter your choice: " choice_remote_sync_local_tgz
  case "$choice_remote_sync_local_tgz" in
  1) sync_with_remote ;;
  2) download_remote_tgz ;;
  3) import_tgz ;;
  0) exit ;;
  *) echo "[ERR] Invalid choice" ;;
  esac
}

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

# Choose sync with remote or import local tgz file
while true; do
  show_choose_remote_sync_local_tgz
  read_choice_remote_sync_local_tgz

  if [ ! -z "$choice_remote_sync_local_tgz" ]; then
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
  echo "No theme selected. Exit."
fi

# Install Node stuff
npm i

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
