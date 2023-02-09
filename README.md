<img src="https://static.kpn.com/ssi/svg/kpn-logo.svg" width="256"/>

#  DSH tutorial: Hello World!

## Introduction
Welcome to the DSH tutorial: Hello World! In this tutorial, you will learn how to set up a simple *Hello World!* service that sends messages to a topic on KPN's Data Services Hub (DSH).

**For who?**
This tutorial is for everyone who wants to work with the DSH and is looking for a place to start. The tutorial is designed to require as little technical knowledge of the as possible and should be completeable after having had only a brief (high-level) introduction into the DSH and how it works.

**Prerequisites:**
 - Install Docker
 - Install Maker
 - Install a code editor (e.g. VS Code)
 - Install Python 
 - Access to a tenant on the Data Services Hub
 - Access to Harbor

**Assumption**

The current tutorial is set-up with the assumption that the user has access to the `training` tenant on the `poc` platform of the DSH. 

 ## 1. Clone git repository

 The first step in this tutorial is to clone this git repository to your local machine. A simple way to do this is as follows:
 
 1. Get the HTTPS URL of this repository by clicking on the green `<> Code` button on this git page.
 2. Open the terminal on your machine
 3. Navigate to the desired directory
 4. Run the following command: 
 
        git clone <git URL>
    where `<git URL>` is the URL from step 1.

 ## 2. Explore the code

The second step is to explore the code from the repository that was cloned in the previous step and make sure that everything is in order for the service to run correctly.
Below you can find a brief description of elements of the repository:
-	`src/example.py`: This is a Python script with the code that produces the messages for our data stream.
-	`Dockerfile`: This is a file with all the specifications needed by Docker to build a Docker image from our code.
-	`Makefile`: This file defines various Docker commands to allow us to easily build and push the docker images to harbor.
-	`dsh` folder: This folder contains code for allowing us to connect to the DSH.

As the focus of this tutorial is not writing code, this code is almost ready-for-use straight out of the box. Only for the `Makefile` it is important to check if the variables at the top are specified correctly:
 -  `PLATFORM` : The platform on which you want to deploy the service
    - This should be `poc`
 - `TENANT` : The tenant on which you want to launch this service
    - This should be `training`
 - `DOCKER_REPO_URL` : The url of the harbor repository to which our your Docker image will be pushed.
    - This should be `registry.cp.kpn-dsh.com/$(TENANT)`
 - `VERSION` : The version of the docker image that we are going to upload. 
    - This can be any string, but why not start at `1`?
 - `tagname`: the name we give our docker image
    - Again, this can be any string. In this tutorial we will use `hello-world`.
 - `tenantuserid`: Your UserID on the tenant.
    - This can be found as follows:
        1. Go to the DSH console (https://console.poc.kpn-dsh.com/)
        2. Login to the `training` tenant
        3. Click on `Resources > Overview`
        4. At the bottom of this page you can see the UserID formatted as `<number>:<number>`. Note that in this field the number only needs to be entered once.
    
## 3. Make Docker image and push to Harbor

In this step a Docker image is build and subsequently pushed it to Harbor. From there it can be used on the DSH to deploy as a service.

Having Maker installed makes this step very simple, because all of the Docker commands are already specified in the `Makefile`. This means that the only actions required in this step are the following:
 1. Open the terminal on your machine
 2. Navigate to the directory of the project
 3. Run the following command[^1]:
          
          make all

[^1]: For those interested in what this command does, please explore its definition in the `Makefile`.

### Optional: Checkout the Docker image on Harbor
By running the `make all` command, the Docker image was pushed to the Harbor repository, where it is stored and ready to be deployed in a service on the DSH. 

The `hello-world` image (along with the others) can be viewed by going to https://registry.cp.kpn-dsh.com/. After having logged in, the image can be found by clicking on `training > training/hello-world`. 
This page shows the different versions[^2] of the image that have been uploaded to Harbor. 
As you can see, the image is also scanned for potential security vulnerabilities. This can be ignored for this tutorial.

[^2]: This version corresponds to the one specified by the `VERSION` variable in step 2. 

## 4. Create the Kafka topic (on the DSH)
Now that our application is available as an image on Harbor, it is finally time to start working on the DSH! 
The first thing that needs to be done on the DSH is to create a Kafka topic to which the `Hello World!` service will send messages. For this, a so-called scratch-topic[^3] (**link to page on scratch-topics**) will be 

The first step is to login to the DSH console (https://console.training.kpn-dsh.com/).

Go to `resources > topics` to get to the overview of which already exist on this tenant. We will then create a new topic for our service, click on the blue `+ Topic` button. 

In the topic creation menu the only things that we still have to provide are the *Topic name* (`hello-world`) and the *# of partitions* (`1`). Fill these in and press the `create topic` button.

[^3]: A scratch topic is a single kafka topic that can only be used and accessed by service from within the tenant in which it is created (Remove when Link is added).

## 5. Create the service (on the DSH)
Our final step is to create the actual service on our tenant that will produce our data stream.

 1. Go to `services > overview` on the DSH console and click on the blue `+ New Service` button. 
 2. Pick a fitting name (e.g. `demo-helloworld`) and continue.
 3. On the next screen you will see a JSON entry containing specifications[^3] for our service. 
 For the service we are setting up in this tutorial, we will need to change the `image` and `env` entries. 
    -	`image` needs to be: 
     
             registry.cp.kpn-dsh.com/training/<image_name>:<version>
        where <image_name> and `<version>` should correspond to the `tagname` and `VERSION` variables specified in step 2.
    -	`env` needs to be: 
         
             { "STREAM": "scratch.<topic_name>.training" } 
        where <topic_name> is the name of your topic chosen in step 4. 
    - Click on the blue `Start service` button.

Congratulations! You have now deployed your first service.
Go to page bla bla to see if it is running sucessfully.
If so next step to inspect the output :)

[^3]: See the bottom of this page for a more detailed explanation of each of the entries (Move to somewhere else).

## 6. View output (on the DSH)
Our service is now live and its producing data on the Kafka topic. In this last step we will show you how you can inspect the output of our service by viewing the Kafka topic. 

The DSH provides two easy ways to view a kafka topic: 
*Kafdrop* or *command line*.
 - *Kafdrop*: Run a Kafdrop application on the DSH and view the topic (**link to page on Kafdrop**).
 - *command line*: Open a command line terminal on the DSH and run the following command:
 
         kcl consume scratch.<topic_name>.training
    where <topic_name> is the name of your topic chosen in step 4. 

## Appendix
