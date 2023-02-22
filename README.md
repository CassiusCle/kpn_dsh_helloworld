<img src="https://static.kpn.com/ssi/svg/kpn-logo.svg" width="256"/>

#  DSH tutorial: Hello World!

## Introduction
Welcome to the DSH tutorial: Hello World! In this tutorial, you will learn how to set up a simple *Hello World!* service that sends messages to a topic on KPN's Data Services Hub (DSH).

**For who?**

This tutorial is for everyone who wants to work with the DSH and is looking for a place to start. The tutorial is designed to require as little technical knowledge of the as possible and should be completeable after having had only a brief (high-level) introduction into the DSH and how it works.

**Prerequisites:**
- Install [Git](https://github.com/git-guides/install-git/)
- Install [Docker](https://www.docker.com/)
- Install GNU Make (First install [Chocolatey](chocolatey.org/install) and then run command ```choco install make``` in the terminal)
- Access to a tenant on the Data Services Hub
- Access to a project on Harbor (of the same name as the tenant on DSH)

If you want to play around with the code and test locally it is also recommended to have a code editor (e.g. VS Code) and Python installed on your machine.

**Assumption**

The current tutorial is set-up with the assumption that the user has access to the `training` tenant on the `poc` platform of the DSH. 

 ## 1. Clone git repository

 The first step in this tutorial is to clone this git repository to your local machine. A simple way to do this is as follows:
 1. Get the HTTPS URL of this repository by clicking on the <!---green `<> Code`--> <img src="https://user-images.githubusercontent.com/24662859/220602264-cd6f39d2-e2fb-41d1-a466-6994c38a8c57.png" height="30"/> button on this git page.
 2. Open the terminal on your machine
 3. Navigate to the directory to which you want to clone the code repository[^1] (e.g. your downloads folder)
 4. Run the following command: 
 
        git clone <git URL>
    where `<git URL>` is the URL from step 1.

[^1]: See [this link](https://www.git-tower.com/learn/git/ebook/en/command-line/appendix/command-line-101#:~:text=To%20change%20this%20current%20working,%24%20cd%20..) if you are unfamiliar with navigating to a folder/directory in the terminal.

 ## 2. Explore the code

The second step is to explore the code from the repository that was cloned in the previous step and make sure that everything is in order for the service to run correctly.
Below you can find a brief description of elements of the repository:
-	`src/example.py`: This is a Python script with the code that produces the messages for our data stream.
-	`Dockerfile`: This is a file with all the specifications needed by Docker to build a Docker image from our code.
-	`Makefile`: This file defines various Docker commands to allow us to easily build and push the docker images to harbor.
- `.gitattributes`: This file prevents the line endings from being converted to CRLF on Windows (necessary for running our service on DSH)
-	`dsh` folder: This folder contains code for allowing us to connect to the DSH.

As the focus of this tutorial is not writing code, this code is almost ready-for-use straight out of the box. Only for the `Makefile` it is important to check if the variables at the top are specified correctly:
 -  `PLATFORM` : The platform on which you want to deploy the service
    - This should be `poc`
 - `TENANT` : The tenant on which you want to launch this service
    - This should be `training`
 - `DOCKER_REPO_URL` : The url of the harbor repository to which your Docker image will be pushed.
    - This should be `registry.cp.kpn-dsh.com/$(TENANT)`
 - `VERSION` : The version of the docker image that we are going to upload. 
    - This can be any string, but why not start at `1`?
 - `tagname`: the name we give our docker image
    - Again, this can be any string. In this tutorial we will use `hello-world`.
 - `tenantuserid`: Your UserID on the tenant.
    - This can be found as follows:
        1. Go to the [DSH Console](https://console.poc.kpn-dsh.com/)
        2. Login to the `training` tenant
        3. Click on `Resources >> Overview`
        4. At the bottom of this page you can see the UserID formatted as `<number>:<number>`. The left number is your UserID. 
        
## 3. Make Docker image and push to Harbor

In this step a Docker image is build and subsequently pushed it to Harbor. From there it can be used on the DSH to deploy as a service.

Having GNU Maker installed makes this step very simple, because all of the Docker commands are already specified in the `Makefile`. This means that the only actions required in this step are the following:
 1. Login to [Harbor](https://registry.cp.kpn-dsh.com/)
 2. On the top-right: Click on `<your_username> >> User Profile`
 3. Remember your `Username` and copy your `CLI secret`
 4. Make sure that Docker is running on your machine
 5. Open the terminal on your machine
 6. Navigate to the directory of the project[^2]
 7. Run the following command[^3]:
          
          make all
 8. Enter the `Username` and `CLI secret` (password) from step 3.
 

[^2]: This is the directory of the code that was cloned in step 2. An easy check is to run the `pwd` (Print Working Directory) command in terminal and check if it outputs a directory ending in `\kpn_dsh_helloworld`. See the first note[^1] for tips on how to navigate the terminal.


[^3]: For those interested in what this command does, please explore its definition in the `Makefile`.

### Optional: Checkout the Docker image on Harbor
By running the `make all` command, the Docker image was pushed to the Harbor repository, where it is stored and ready to be deployed in a service on the DSH. 

The `hello-world` image (along with the others) can be viewed on [Harbor](https://registry.cp.kpn-dsh.com/). After having logged in, the image can be found by clicking on `training >> training/hello-world`. 
This page shows the different versions[^4] of the image that have been uploaded to Harbor. 
As you can see, the image is also scanned for potential security vulnerabilities. This can be ignored for this tutorial.

[^4]: This version corresponds to the one specified by the `VERSION` variable in step 2. 

## 4. Create the Kafka topic (on the DSH)
Now that our application is available as an image on Harbor, it is finally time to start working on the DSH! 
The first thing that needs to be done on the DSH is to create a Kafka topic to which the `Hello World!` service will send messages. For this, a so-called scratch-topic[^5] <!--- TODO: link to page on scratch-topics.--> will be used. A new Kafka topic is created as follows:
1. Login to the [DSH Console](https://console.training.kpn-dsh.com/).
2. Go to `resources >> topics` and click on the <!---blue `+ Topic`--> <img src="https://user-images.githubusercontent.com/24662859/220603073-b49f875d-d3f4-4dde-b0e0-7388a575422c.png" height="30"/> button.
3. Fill in the *Topic name* (`hello-world`) and the *# of partitions* (`1`). 
4. Press the <!--`create topic`--> <img src="https://user-images.githubusercontent.com/24662859/220603333-84e993f9-018b-4017-9d5d-a074c2ef619a.png" height="30"/> button.

[^5]: A scratch topic is a single kafka topic that can only be used and accessed by service from within the tenant in which it is created.

## 5. Create the service (on the DSH)
The final step is to create the actual service on our tenant that will produce and consume the messages from the topic:
 1. Go to `services >> overview` on the DSH console and click on the <!---blue `+ New Service`--> <img src="https://user-images.githubusercontent.com/24662859/220603879-c36503af-5ee2-4044-b3f8-dd64aa9eacd7.png" height="30"/> button.
 2. Pick a fitting name (e.g. `demo-helloworld`) and continue.
 <!---3. The next screen shows a JSON entry containing the specifications[^5] for our service. -->
 3. The next screen shows a JSON entry containing the specifications for our service. 
 For the service of this tutorial, only the `image` and `env` entries need to be changed: 
    -	`image` needs to be: 
     
             registry.cp.kpn-dsh.com/training/<image_name>:<version>
        where `<image_name>` and `<version>` should correspond to the `tagname` and `VERSION` variables specified in step 2.
    -	`env` needs to be: 
         
             { "STREAM": "scratch.<topic_name>.training" } 
        where `<topic_name>` is the name of your topic chosen in step 4. 
 4. Click on the <!---blue `Start service`--> <img src="https://user-images.githubusercontent.com/24662859/220604054-cc21d7f3-b120-4b22-9231-84c22c56c190.png" height="30"/> button.

Congratulations! You have now deployed your first service.

On the DSH Console, the service can be seen in the list when navigating to `services >> overview`. Clicking on the service will show you its status and allow you to start/stop/delete it as well as give you access to the (error)logs produced during its deployment. If the service is running succesfully, the last thing to check-out is to inspect the data stream it produces (see the next step).

<!---[^5]: See the bottom of this page for a more detailed explanation of each of the entries (Move to somewhere else).-->

## 6. View output (on the DSH)
Our service is now live and its producing data on the Kafka topic. This step will show how to inspect the output of the service by viewing the Kafka topic. 

The DSH provides two easy ways to view a Kafka topic: 
*Kafdrop* or *command line*.
 - *Kafdrop*: Run a Kafdrop application on the DSH and view the topic (**link to page on Kafdrop**).
 - *command line*: Open a command line terminal on the DSH and run the following command:
 
         kcl consume scratch.<topic_name>.training
    where `<topic_name>` is the name of your topic chosen in step 4. 

## 7. Stop the service (on the DSH)
The last step of this tutorial is to stop the service we have just created and deployed. Otherwise, it will keep producing output and using resources on this tenant. 
The way to stop a service is as follows:
 1. Go to `services >> overview` on the DSH console and click on the service that was created in step 5. 
 2. Click on the <!---blue `□`--> <img src="https://user-images.githubusercontent.com/24662859/220604297-23835a26-11a1-40f6-9969-63006495a034.png" height="30"/> button to stop the service.
 3. (Optional): If you are certain that you will not (want to) use this service again, you can also remove the service by clicking the <!---red trash-bin--> <img src="https://user-images.githubusercontent.com/24662859/220604313-2db36764-3435-403e-8627-79414326f935.png" height="30"/> button on the top right.
