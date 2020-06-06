---
title: Shell scripts for starting new projects
published: false
description: Custom made shell script for starting new project
tags: shell, bash, scripting
---

Recently I realized that I do a lot of repetitive steps when starting a new project. So I started to think if there was a way to automate that process.

Of course, I could have done this in a lot of different languages such as Python, C, PHP or any other, but I decided I wanted to do this in shell script (bash).

Now some of you might be asking yourself "But why would you do that in bash?", and my answer to you is why wouldn't I. 

I've done some minor stuff with it before but never really gotten to deep into learning it or truly trying to find out how it all works. I always viewed it as something you would see in movies when they show those "hacking" scenes. 
   
   
![Man sitting behind a computer and typing on a keyboard](https://media.giphy.com/media/l46C6sdSa5DVSJnLG/giphy.gif "Scene from the Hackerman movie") 


I always admired people who could write and understood what it does. So I decide the best way to learn it was to get my hands dirty with it. I started by trying to come up with an idea for what the script should do and coming up with some basic concepts, and that is how all of this started. 

### So what are the steps I usually take when starting a new project?
 
* Give the project a name
* Create the project folder
* Initialize the folder as git repository
    * Add git repo url
* Create a database for the project
* Create virtual host setup
* Depending on the language of choice set up additional things, such as:
    * composer
    * npm


So I started to lookup up documentation and tutorials on creating shell scripts and managed to create one I'm ok with using in my daily work.

The basic usage of the script:

```
create-project.sh <project-name>
```

or you can use it with arguments:

```
create-project.sh <project-name> [-h | -p | -g | -e | -l | -q]
```

### Explanation of arguments

You can pass all or none of the arguments as they all have predefined default values that will be used.

* **-h or --help** Is used to display the help text that shows all the arguments and usage
* **-p or --path** Is used to set the path of the project and falls back to the current directory if empty
* **-g or --git**  Is used to specify the git repo url for the project
* **-q or --quite** Is used to suppress all output and prompts from the script except for errors
* **-e or --editor** Is used to set which code editor will be opened once the script has completed
* **-l or -lang or --language** Is used to specify in which language the project will be built in so that it can run default setups (such as npm init) 

I created this script in hopes of improving my knowledge of shell scripting and to help me with the boring repetitive task I had to do when starting a new project.

The script is under active development, and I will be making some changes to it as I think of new stuff to add or learn something new. 

If you have any suggestions, feedback or improvements leave a comment or create a pr on GitHub. 

You can find the whole source for the script @ [Github](https://github.com/gigili/create-project) released under GPL-3.0 licence

{% github gigili/create-project no-readme %}