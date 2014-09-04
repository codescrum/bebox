Bebox
=====

[![Code Climate](https://codeclimate.com/github/codescrum/bebox/badges/gpa.svg)](https://codeclimate.com/github/codescrum/bebox)
[![Test Coverage](https://codeclimate.com/github/codescrum/bebox/badges/coverage.svg)](https://codeclimate.com/github/codescrum/bebox)

Introduction
------------

Bebox is designed to meet provisioning goals for small to medium environments (maybe even big ones) while using [Puppet (opensource)](http://puppetlabs.com/puppet/puppet-open-source), and without the need for a Puppet Master. This project is intended for teams that tipically use two repositories for each project: the "app" repo and the "provisioning" repo. This project centers its efforts in trying to organize how these "provisioning" repos are constructed.

Bebox was originally born from the necessity of automating the provisioning of environments in which [Rails](https://github.com/rails/rails) web applications could run, with the least amount of steps, and be able to reproduce the production setup every time. Please note that, even while this is the genesis for Bebox, it does not imply that it is specifically tailored for provisiong web applications, and we think it can ultimately be used pretty much in any scenario where Puppet is used without overwhealming complexity.

Bebox's main concern is __organization__. It is generally a good idea to have conventions about how different source code files are placed and named and be able to use this to reduce the details required to understand a project while also providing automation in key places. These conventions may include things like from how to write modules, integrate them into the projects, a directory structure for the projects to follow, how to have a replicated “development/test” environment into virtual machines, etc.

NOTE: For the moment, Bebox assumes that the remote machines' OS is Debian based.

Bebox development is based on awesome tools on their own, and essentially based on the following:

* Written in Ruby and distributed as a gem
* It has a very nice CLI based on a commandline tool framework called [GLI](https://github.com/davetron5000/gli)
* Uses [Puppet (opensource)](http://puppetlabs.com/puppet/puppet-open-source) for provisioning machines, and its the main component that the Bebox workflow aims to organize.
* Uses [vagrant](http://www.vagrantup.com/) for setting up a similar development/test environment in accordance to the remote machines real setup.
* Uses [Capistrano](http://capistranorb.com/) for automating the tasks to be executed on remote/vagrant machines.

Workflow
--------

Bebox’s workflow is comprised of the five (5) phases explained below:

###Project creation phase

In this phase, the project skeleton is created, just like when a rails app is created. Keep in mind we are generating a "provisioning" repo skeleton and much of the logic behind bebox is put directly into the generated code so it can be tuned.

###Environment definition phase

Any number of environments are defined. By default, the 'vagrant', 'staging', and 'production' environments are present. You an create any number of environments you need. The 'vagrant' environment is special as it is designed to run in virtual machines hosted in the local machine.

###Node allocation phase

For each environment, there can be any number of nodes. The nodes for every environment are configured. A node represents a machine or server, a node's critical attributes are only it's hostname and ip address.

###Prepare phase

In this phase, all nodes are equipped with a set of base packages and tools via Capistrano which sole purpose is to help install Puppet. Also, very importantly, each node gets a Puppet opensource standalone installation. In order for Capistrano to be able to connect and install this in each node, a set of keys must already be present as authorized_keys in the remote servers, Bebox reminds of this step, and will possibly help do this semi-automatically in the future (requires user input because of boostraping from a root password). You will notice that Puppet installer files are bundled with Bebox, to use a fixed Puppet opensource version. This was necessary to ensure a particular Puppet version to avoid breaking things.

###Provisioning phase

Once Puppet is installed, we can use it to provision anything we want. The provisioning phase is the last phase of the project and consists (currently) of four steps. This steps has a clear separation of concerns which we have chosen based on practical experience, however this is the default and you can add or remove any number of steps, but we recommend at least to stick with the first two.

Steps were created to run sequential puppet runs and apply multiple manifests in order. Although this may seem strange, Puppet's non-deterministic manner is something that is not suitable every time and having only one manifest to pack everything into can create some trouble with dependant modules.

Also, the idea of steps helps in visualizing/imagining layers of configuration.

Coming back to the steps, the four default steps that have been put into Bebox's projects by default are:

####Fundamental step (0-fundamental)
This step only provides a 'puppet' user, which the following steps use to install everything else (instead of using root). This is done to have all environments as similar as possible. In the 'vagrant' environment, the main user is 'vagrant', but this could also be 'root' or something else, so this ensures that a single user (other than root) for making changes via Puppet is created.

####The user layer step (1-users)
Based on practical experience, this next step should be the one responsible for setting system users, so that they exist prior to any service level provisioning.

####The service layer step (2-services)
This step is what you would have in your regular puppet provisioning repo (except for the users of course). We follow the roles and profiles scheme (links to read about [here](http://www.craigdunn.org/2012/05/239/) and [here](http://garylarizza.com/blog/2014/02/17/puppet-workflow-part-2/)) and install the majority of the functional services, web, database, etc.

####The security layer step (3-security)
This step configure some packages to provide a minimal security in the system (fail2ban, ssh access, iptables).


NOTE: Probably many people would think this is not advisable, so there is always the possibility of having only one step, one run, one manifest for Puppet to run in this phase.

How to Use
----------

### Bebox demo

You can see a bebox demo video for a complete example of provisioning a machine and deploying a rails application in it.

[![bebox demo video](http://img.youtube.com/vi/mioeMsuKJr4/0.jpg)](http://www.youtube.com/watch?v=mioeMsuKJr4)

Also you can find the provision and rails app code sample projects in:

* [A puppet repo generated by bebox to deploy a sample rails app.](http://github.com/codescrum/bebox-sample-puppet-generated-repo)

* [A demo ruby on rails app deployed from a puppet repo generated by bebox.](http://github.com/codescrum/sample-rails-app-for-bebox)


###Installation

Pre-requisites

* rbenv
* ruby version >= 1.9.2 (ruby 2.1.0 recommended)
* vagrant (tested using vagrant 1.6.3)

####Install bebox:

In the directory where you want to install bebox do:

    gem install bebox

###Bebox project creation (Project creation phase).

To create a new bebox project do:

    bebox new PROJECT_NAME

In console appears a simple wizard to configure a vagrant box for the project. The vagrant box can be downloaded automatically with the wizard or linked with an existent local *.box file.

This creates a subdirectory named *bebox-[PROJECT_NAME]* with the initial skeleton of application. To access new bebox commands (much like Rails does) cd into the newly created bebox project:

    cd bebox-[PROJECT_NAME]

###Manage Environments (Environment definition phase).
Then you can add/remove/list environments. By default: the production, staging and vagrant environments are already created.

To add an environment:

    bebox environment new ENVIRONMENT

To remove an environment:

    bebox environment remove ENVIRONMENT

To list environments:

    bebox environment list

###Manage Nodes (Node allocation phase).
If you have at least one environment you can add/remove/list nodes.

To add a node:

    bebox node new

Then in the console a simple wizard appear asking the node parameters.

To remove a node:

    bebox node remove

Then in the console a simple wizard appear for selecting the node to remove from the available nodes.

To list nodes:

    bebox node list [--environment ENVIRONMENT] [--all]

Without options it list nodes for the default *ENVIRONMENT* that is **vagrant**. If you provide the *ENVIRONMENT* flag it list nodes for that environment or if the *--all* switch is set list all nodes for all environments.


###Prepare Nodes (Prepare phase).
If you have nodes configured then you can prepare them.

To prepare them:

    bebox prepare [--environment ENVIRONMENT]

It will prepare all nodes that are not prepared. If you have nodes already prepared (For example you add a new node after prepare previous nodes), a wizard appear to ask if you want to re-prepare them. It will not prepare nodes that you don't want to re-prepare.

By default if an *ENVIRONMENT* is not specified the default will be **vagrant**.

Also if the nodes are in the vagrant environment you can up/halt the vagrant machines:

**Take in account that this phase would take some time while it download and configure the base packages in all the nodes to be prepared.**

For vagrant nodes already prepared you can stop/start the vagrant machines with:

    bebox vagrant_halt

    bebox vagrant_up

###Puppet (Provisioning phase)

If you have nodes prepared you can provision them step-by-step. All steps can be applied without restrictions. If you want to configure the provisioning we encourage to use the roles and profiles pattern thath we implement through a special set of commands (See parts below).

At project creation a set of default roles, profiles and hiera data are configured for the nodes in the steps (0, 1 and 3), but you could re-configuring in any moment. The step-2 need to be configured completely.


To provision the nodes:

    bebox apply [STEP] [--environment ENVIRONMENT] [--all]


The STEP option must be one of: *step-0*, *step-1*, *step-2*, *step-3*
By default if an *ENVIRONMENT* is not specified the default will be **vagrant**.
The *--all* switch allows to run all steps in order without specify the STEP option.

**We recommend to configure the roles, profiles and hiera data previously to apply any step.**

####Manage roles

To add a role:

    bebox role new ROLE

To remove a role:

    bebox role remove ROLE


Then in the console a simple wizard appear for selecting the role to remove from the available roles.

To list roles:

    bebox role list

**We recommend to use our default roles (fundamental, users, security) for steps (0, 1, 3), but you can edit or delete them under your own risk**

####Manage profiles

To add a profile:

    bebox profile new PROFILE [-p PATH]

This command creates a file structure for the profile with templates that you need to edit for the profile do something.
The structure is like:

    ── profiles/
        └── <category1>/
            └── <category2>/
                ...
                └── <categoryN>/
                    └── <profile-name>/
                        ├── manifests/
                        │   └── init.pp
                        └── Puppetfile

The *categories (category1, category2, ... categoryN)* are set if the argument *-p PATH* is passed; and are useful better organization of profiles.

For example:

    bebox profile new iptables -p basic/security

would create the profiles directories structure:

    ── profiles/
        └── basic/
            └── security/
                └── iptables/
                    ├── manifests/
                    │   └── init.pp
                    └── Puppetfile

You need to modify the init.pp file adding usual puppet calls to classes, resources, modules, hiera.
You need to modify the Puppetfile to set the modules that the manifest file will use.
Also you need to modify the hiera data that the manifest will use (See Hiera part below).

To remove a profile:


    bebox profile remove


Then in the console a simple wizard appear for selecting the profile to remove from the available profiles.

To list profiles:


    bebox profile list

**We recommend to use our default profiles (fundamental, users, security) for steps (0, 1, 3), but you can edit or delete them under your own risk**

**Important:** Remember that you need to write/edit the puppet code for the profiles to work (specially step-2 that has no defaults); also you have to write/edit the Puppetfile template created to add modules that your profile use; additionally if you call hiera data from a profile you need to add them in the hiera/data/<data>.yaml file in the structure created (see Hiera part below)


####Associate roles and profiles

This add/remove a profile to a role.

To add a profile to a role:

    bebox role add_profile

Then in the console a simple wizard appear for selecting the role and profile to add.

To remove a profile from a role:

    bebox role remove_profile

Then in the console a simple wizard appear for selecting the role and profile to remove.

To list profiles configured in a role:

    bebox role list_profiles ROLE

####Associate nodes and roles

This change the role associated with a specific node.

To set the role for a specific node:


    bebox node set_role [--environment ENVIRONMENT]

Then in the console a simple wizard appear for selecting the node and role to set.
By default if an *ENVIRONMENT* is not specified the default will be **vagrant**.


###Hiera

If you use hiera data from your profiles, you can add them to the appropiate file in the file structure shown below:

    ── puppet/
        └── steps/
           ├── 0-fundamental/
           ├── 1-users/
           ├── 2-services/
           ├── 3-security/
               ├── hiera/
               │   └── data/
               │   │   └── [node].yaml
               │   │   └── [environment].yaml
               │   │   └── common.yaml
               │   └── hiera.yaml
               ├── manifests/
               │   └── site.pp
               ├── modules/
               └── Puppetfile (Automatically generated by Bebox in every 'apply')

Each of the *<number>-<step-name>* directories corresponds to a provisioning step phase. For example **0-fundamental** correspond to **step-0** option.

To add hiera data you need to edit any of the **[node].yaml**, **[environment].yaml**, **common.yaml**.
[node]: correspond to the hiera file for the node hostname (Ex. node0.server1.com.yaml).
[environment]: correspond to the hiera file for the node hostname (Ex. vagrant.yaml, production.yaml).


Development
-----------

To use the project in development mode, you need to do this:

* Clone bebox from the repository.

        git clone https://github.com/codescrum/bebox.git

* Run bundle to install

        bundle install

* Generate the gem package

        rake package

* Make a tmp directory inside bebox folder

        mkdir tmp
        cd tmp

* Execute the project creation command preceded by **bundle exec**

        bundle exec bebox new PROJECT

* Enter to the project created

        cd PROJECT

* Add to the **Gemfile** the line

        gem 'bebox', :path => "BEBOX_PATH_IN_YOUR_PC/pkg"

* Execute any project commands preceded by **bundle exec**

        bundle exec bebox environment

Tests
-----

Before running any tests you need to configure the IP address for the vagrant machine. To do this create the file *spec/support/config_specs.yaml* from the *spec/support/config_specs.yaml.example* and configure a local newtwork IP free address to use.

By project's nature the specs must be run in order. To do this all specs has a 'Test XX:' naming convention. If you want to run all tests in order we have a ordered_phases_spec.rb file than you can run with.

    rspec spec/ordered_phases_spec.rb

Maybe it would take a large time because it creates a vagrant machine and do a basic provision downloading packages and installing them in the machine.

**Important:** You need to have the [ubuntu-server-12042-x64-vbox4210-nocm.box](http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box) in the bebox root folder to run the tests
