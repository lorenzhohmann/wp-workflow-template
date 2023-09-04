# WordPress Workflow Template

This template is a boilerplate for a **fully automated WordPress Development workflow**.

## ✨ Features ✨

- **Full local Development Environment** (includes Webserver, Database and phpmyadmin)
- **Code Quality and CI Tools** (includes Linting, Formatting for HTML, CSS, JS, TS and PHP)
- **CI & CD** (Continuous Integration & Continuous Delivery/Deployment) steps for GitHub Actions
- **Automated Code Formatting** before Commit
- Installation of **recommended VSCode Extensions**
- A **script to setup a live website** into this boilerplate
- **Git Workflow** with Code Reviews and Pull Requests
- Optional **JS & CSS Minify** on Delivery/Deploy

## Requirements (Preparation of your machine)

- [Visual Studio Code](https://code.visualstudio.com/) as IDE
- Install [Node.js](https://nodejs.org/en) (> version 18) on your system (helpful to update our Node.js version: https://dev.to/hasidicdevs/)how-to-install-nodejs-as-a-non-root-user-using-nvm-a-step-by-step-guide-424e)
- [WSL2 with Ubuntu](https://learn.microsoft.com/de-de/windows/wsl/install) strongly recommended!
- Installation of some global npm packages:
  - linux: `sudo npm i -g eslint prettier eslint-config-airbnb eslint-plugin-prettier eslint-config-prettier`
  - windows: `npm i -g eslint prettier eslint-config-airbnb eslint-plugin-prettier eslint-config-prettier`

## Installation

Some little adjustments needs to be made to use this repository:

- Create a folder and clone this repository with `git clone https://github.com/lorenzhohmann/wp-workflow-template .` inside the empty folder.
- Run the _setup-repo.sh_ script (run `chmod +x setup-repo.sh` and `./setup-repo.sh`)
- Create a Personal access token under **Settings > Developer settings > Personal access tokens > Generate new token (classic)** and create a new variable _PAT_ in your repository settings under **Secrets and variables > 'Secrets' tab > New repository secret**

## Setup the WordPress website

- Run the _import.sh_ script (run `chmod +x import.sh` and `./import.sh`) to import your website or to create a new website
- Start the app with `docker compose up -d`
- Open phpmyadmin (http://localhost:8081) and import your database
- Develop!

## Understanding the workflow

- Make sure to checkout the **develop** branch by using `git checkout develop`. Run `git branch develop` before, if the branch doesn't exist
- Run `git pull` every time before you make changes
- Make your changes, commit them and push them to the remote repository
- Once the changes are pushed, GitHub executes Code Linting and Formatting in the Background
- Create a PR (pull request) and have a code review done by another developer
- After the other developer accepts the change, the theme is automatically deployed to your production system

## Pre-Commit Hook (Husky)

- Before a commit is made, code linting and formatting is automatically executed

## Rewrite Base URL

```sql
UPDATE wp_options SET option_value = replace(option_value, 'oldurl.com', 'newurl.com') WHERE option_name = 'home' OR option_name = 'siteurl';
UPDATE wp_posts SET guid = replace(guid, 'oldurl.com','newurl.com');
UPDATE wp_posts SET post_content = replace(post_content, 'oldurl.com', 'newurl.com');
UPDATE wp_postmeta SET meta_value = replace(meta_value,'oldurl.com','newurl.com');
```

## Stop app

```
docker compose down
```

The command above stops the app. If you want to reset the database use `docker compose down -v`

## Support/Issues

If you've got another idea for improving this workflow or to report a bug, feel free to [open an issue](https://github.com/lorenzhohmann/wp-workflow-template/issues/new/choose).
