<img src="https://static.kpn.com/ssi/svg/kpn-logo.svg" width="256"/>

#  DSH tutorial: Hello World!

Introductory text....


**Goal:**

Learn how to set up a simple *Hello World!* service on the Data Services Hub (DSH) that sends messages to a topic.


**Prerequisites:**
 - Install Docker
 - Install Maker
 - Install a code editor (e.g. VS Code)
 - Install Python 
 - Access to a tenant on the Data Services Hub
 - Access to Harbor

**Assumption**

The current tutorial is set-up with the assumption that the user has access to the `training` tenant on the `poc` platform. 

 ## 1. Clone git repository


 The first step in this tutorial is to clone this git repository to your local machine. A simple way to do this is as follows:
 
 1. Get the HTTPS URL of this repository by clicking on the green `<> Code` button on this git page.
 2. Open your terminal
 3. Navigate to the desired directory
 4. Run the following command: 
 
        git clone <git URL>
    where `<git URL>` is the URL from step 1.

 ## 2. Edit Makefile

One of the files in the repository that you just cloned is called `Makefile`. Open this file in a code editor and check if the variables at the top are correctly specified:
 -  `PLATFORM` : The platform on which you want to deploy the service
    - Should be `poc`
 - `TENANT` : The tenant on which you want to launch this service
    - Should be `training`
 - `DOCKER_REPO_URL` : The url of the harbor repository to which our your Docker image will be pushed .
    - Should be `registry.cp.kpn-dsh.com/$(TENANT)`
 - `VERSION` : The version of the docker image that we are going to upload. 
    - Free to choose, but why not start at 1?
 - `tagname`: the name we give our docker image
    - Again free to choose, in this tutorial we will use `hello-world`
 - `tenantuserid`: Your UserID on the tenant.
    - You can find this as follows:
        1. Go to the DSH console (https://console.poc.kpn-dsh.com/)
        2. Login to the `training` tenant
        3. Click on `Resources > Overview`
        4. At the bottom of this page you can see your UserID formatted as `<number>:<number>`. Note that you only need to enter the number once in this field.
    
## 3. Make Docker image and push to Harbor

In this step we build the docker image and subsequently push it to harbor. From there it can be used on the DSH to deploy as a service.

Having Maker installed makes this step very simple, because all of the Docker commands are already specified in the `Makefile` of this repository. This means that we can complete this step by navigating to the directory of this project and running the following command: 
```
make all
```

If you are interested to learn what exactly this command does, we encourage you to check out its definition in line 28 in the `Makefile`.

### Optional: Checkout the Docker image on Harbor
By running the `make all` command, we pushed our container to the Harbor repository, where it is stored and ready to be deployed in a service on the DSH. 

You can view our `hello-world` image along with others by going to https://registry.cp.kpn-dsh.com/. After having logged in, our image can be found by clicking on `training > training/hello-world`. 
On this page you can see the different versions[^1] that have been uploaded to Harbor. 
As you can see, the image is also scanned for potential security vulnerabilities. You can ignore these for now, but keep in mind that it is important to check that your service does not introduce vulnerabilities.

[^1]: This version corresponds to the one specified by the `VERSION` variable in step 2. 

## 4. Create the Kafka topic
Now that we have build our application, containerised it and pushed it to the relevant repository, we can finally start our work on the DSH! We first login to the DSH through the console on https://console.training.kpn-dsh.com/.

We will now create a Kafka topic to which our `Hello World!` service will send messages. In this tutorial, we will be using a so called scratch-topic[^2] (**link to page on scratch-topics**). 

Go to `resources > topics` to get to the overview of which already exist on this tenant. We will then create a new topic for our service, click on the blue `+ Topic` button. 

In the topic creation menu the only things that we still have to provide are the *Topic name* (`hello-world`) and the *# of partitions* (`1`). Fill these in and press the `create topic` button.

[^2]: A scratch topic is a single kafka topic that can only be used and accessed by service from within the tenant in which it is created (Remove when Link is added).

## 5. Create the service
Our final step is to create the actual service on our tenant that will produce our data stream.

 1. Go to `services > overview` on the DSH console and click on the blue `+ New Service` button. 
 2. Pick a fitting name (e.g. `demo-helloworld`) and continue.
 3. On the next screen you will see a JSON entry containing specifications[^3] for our service. 
 For the service we are setting up in this tutorial, we will need to change the `image` and `env` entries. 
    -	`image` needs to be: 
     
             registry.cp.kpn-dsh.com/training/<image_name>:<version>
        where <image_name> and `<version>` should correspond to the `tagname` and `VERSION` variables specified in step 2.
    -	`env` needs to be: 
         
             { "STREAM": "scratch.test.<topic_name>" } 
        where <topic_name> is the name of your topic chosen in step 4. 
    - Click on the blue `Start service` button.

Congratulations! You have now deployed your first service.
Go to page bla bla to see if it is running sucessfully.
If so next step to inspect the output :)

[^3]: See the bottom of this page for a more detailed explanation of each of the entries (Move to somewhere else).

## 5. View the Kafka topic (output)
Our service is now live and its producing data on the Kafka topic. In this last step we will show you how you can inspect the output of our service by viewing the Kafka topic. 

The DSH provides two easy ways to view a kafka topic: 
*Kafdrop* or *command line*.
 - *Kafdrop*: Run a Kafdrop application on the DSH and view the topic (**link to page on Kafdrop**).
 - *command line*: Open a command line terminal on the DSH and run the following command:
 
         kcl consume scratch.test.<topic_name>
    where <topic_name> is the name of your topic chosen in step 4. 
