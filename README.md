# Create project script

Shell script that helps you when starting a new project by doing repetitive manual task for you

# Setup

* Download this script to your computer
* Add the execution permission to it with `chmod +x create-project.sh`

Optional:

*  For global access to the create project script you can also copy it somewhere like `/usr/local/bin`
  *   `cp create-project.sh /usr/local/bin/create-project`

# The basic usage of the script

```shell
create-project.sh <project-name>
```

or you can use it with arguments:

```shell
create-project.sh <project-name> [-h | -p | -g | -e | -l | -q]
```

## Explanation of arguments

You can pass all or none of the arguments as they all have predefined default values that will be used.

* -h or --help Is used to display the help text that shows all the arguments and usage
* -p or --path Is used to set the path of the project and falls back to the current directory if empty
* -g or --git Is used to specify the git repo url for the project
* -q or --quite Is used to suppress all output and prompts from the script except for errors
* -e or --editor Is used to set which code editor will be opened once the script has completed
* -l or -lang or --language Is used to specify in which language the project will be built in so that it can run default setups (such as npm init)

## Config

There are a few variables that my not be the same for your setup as it is for mine. Those variables are:
* `MYSQL_USER`
* `MYSQL_PASSWORD`
* `VIRTUAL_HOST_PATH`

also the script assumes you're using `httpd` for your webserver which may or may not be the case for you. If you're using something else please update that on [line 284]( https://github.com/gigili/create-project/blob/bf14032eb6f4ce5b12484d7045c5d3738c194da9/create-project.sh#L284). Also the setup of the virtual host is done for the apache webserver so if you're using ngnx or something different you might need to update the virtual host [config template](https://github.com/gigili/create-project/blob/bf14032eb6f4ce5b12484d7045c5d3738c194da9/create-project.sh#L236)

# NOTE:

*I take no responsibility should this script affect your PC or anything else in any way. By using it, you acknowledge that you understand what this script does and how it may affect you or your system.*
