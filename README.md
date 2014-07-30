
Bebox
=====

Introduction
------------

Bebox is a project born from the necessity of organizing a way to deal with the provisioning of remote servers. Bebox is based on puppet and much like another quite known project Boxen, the idea is to have a good agreement on how to manage a puppet repo for a remote environment. It is also a good idea to have a standard approach on dealing with the provisioning problem, including how to write modules, integrate them into the projects, a directory structure for the projects to follow, how to have a replicated “development/test” environment into virtual machines, etc.

Bebox uses many great tools for its workflow, but essentially is based on the following:

* Written in Ruby
* A commandline tool framework called GLI and acts as a project skeleton generator
* Does the provisioning and organizes the workflow (hopefully) for Puppet (opensource)
* Uses http://www.vagrantup.com/ for development/test setup of the remote environment (multimachine too)
* Uses Capistrano for deployment of the puppet files and running the commands to provision the remote machines.

Workflow
--------

Bebox’s workflow can be better understood if we take into account that there are some defined phases which are:

###Project creation phase

In this phase, the project skeleton is created, just like when a rails app is created.

###Environment definition phase

Any number of environments are defined. By default, the vagrant, staging, and production environments are present, and represents the remote environment in a local vagrant configuration (to perform tests and stuff).

###Node allocation phase

The nodes for every environment are configured. A node represents a machine or server, so it has a hostname and IP.

###Prepare phase

This phase install in previously defined nodes a set of base packages (SO, development dependencies, Puppet).

###Provisioning phase (puppet)

The provisioning phase is the last phase of the project and consists (currently) of four steps. This steps has a clear separation of concerns which we have chosen based on practical experience.

####Fundamental step (0-fundamental)
This step only provides a puppet user, which the following steps use to provide everything else. This is done to have every environment as similar as possible to any other. In the vagrant environment, the main user is vagrant, but in other systems could be root or something else.

####The user layer step (1-users)
Based on practical experience, this step should be the one responsible for setting the application user and any other initial permissions and access.

####The service layer step (2-services)
This step is what you would have in your regular puppet installation (except for the users of course). This would use the roles and profiles scheme and install the majority of the functional services, web, database, and rest of the stuff.

####The security layer step (3-security)
This step configure some packages to provide a minimal security in the system (fail2ban, ssh access, iptables).


How to Use
----------
###Installation

Pre-requisites

The following must be installed for bebox to works well:
* rbenv
* ruby version >= 1.9.2 (2.1.0 recommended)
* vagrant

Install bebox:

```
gem install bebox
```
###Bebox project creation (Project creation phase).

From any directory:
```
bebox new PROJECT_NAME
```

In console appear a simple wizard to configure a vagrant box in the project. The vagrant box can be downloaded automatically with the wizard or linked with an existent local *.box file.

This creates a subdirectory *bebox-[PROJECT_NAME]* with the initial skeleton of application. To access new bebox commands do:

```
cd bebox-[PROJECT_NAME]
```

###Manage Environments (Environment definition phase).
Then you can add/remove/list environments. By default: the production, staging and vagrant environments are already created.

To add an environment:

```
bebox environment new ENVIRONMENT
```
To remove an environment:

```
bebox environment remove ENVIRONMENT
```
To list environments:

```
bebox environment list
```

###Manage Nodes (Node allocation phase).
If you have at least one environment you can add/remove/list nodes.

To add a node:

```
bebox node new
```

Then in the console a simple wizard appear asking the node parameters.

To remove a node:

```
bebox node remove
```

Then in the console a simple wizard appear for selecting the node to remove from the available nodes.

To list nodes:

```
bebox node list [--environment ENVIRONMENT] [--all]
```

Without options it list nodes for the default *ENVIRONMENT* that is **vagrant**. If you provide the *ENVIRONMENT* flag it list nodes for that environment or if the *--all* switch is set list all nodes for all environments.


###Prepare Nodes (Prepare phase).
If you have nodes configured then you can prepare them.

To prepare them:

```
bebox prepare [--environment ENVIRONMENT]
```

It will prepare all nodes that are not prepared. If you have nodes already prepared (For example you add a new node after prepare previous nodes), a wizard appear to ask if you want to re-prepare them. It will not prepare nodes that you don't want to re-prepare.

By default if an *ENVIRONMENT* is not specified the default will be **vagrant**.

Also if the nodes are in the vagrant environment you can up/halt the vagrant machines:

**Take in account that this phase would take some time while it download and configure the base packages in all the nodes to be prepared.**

For vagrant nodes already prepared you can stop/start the vagrant machines with:

```
bebox vagrant_halt
```

```
bebox vagrant_up
```

###Puppet (Provisioning phase)


If you have nodes prepared you can provision them step-by-step. All steps can be applied without restrictions. If you want to configure the provisioning we encourage to use the roles and profiles pattern thath we implement through a special set of commands (See parts below).

At project creation a set of default roles, profiles and hiera data are configured for the nodes in the steps (0, 1 and 3), but you could re-configuring in any moment. The step-2 need to be configured completely.


To provision the nodes:

```
bebox apply [STEP] [--environment ENVIRONMENT] [--all]
```

The STEP option must be one of: *step-0*, *step-1*, *step-2*, *step-3*
By default if an *ENVIRONMENT* is not specified the default will be **vagrant**.
The *--all* switch allows to run all steps in order without specify the STEP option.

**We recommend to configure the roles, profiles and hiera data previously to apply any step.**

####Manage roles

To add a role:

```
bebox role new ROLE
```

To remove a role:

```
bebox role remove ROLE
```

Then in the console a simple wizard appear for selecting the role to remove from the available roles.

To list roles:

```
bebox role list
```

**We recommend to use our default roles (fundamental, users, security) for steps (0, 1, 3), but you can edit or delete them under your own risk**

####Manage profiles

To add a profile:

```
bebox profile new PROFILE [-p PATH]
```

This command creates a file structure for the profile with templates that you need to edit for the profile do something.
The structure is like:
```
── profiles/
    └── <category1>/
        └── <category2>/
            ...
            └── <categoryN>/
                └── <profile-name>/
                    ├── manifests/
                    │   └── init.pp
                    └── Puppetfile
```
The *categories (category1, category2, ... categoryN)* are set if the argument *-p PATH* is passed; and are useful better organization of profiles.

For example:
```
bebox profile new iptables -p basic/security
```
would create the profiles directories structure:
```
── profiles/
    └── basic/
        └── security/
            └── iptables/
                ├── manifests/
                │   └── init.pp
                └── Puppetfile
```

You need to modify the init.pp file adding usual puppet calls to classes, resources, modules, hiera.
You need to modify the Puppetfile to set the modules that the manifest file will use.
Also you need to modify the hiera data that the manifest will use (See Hiera part below).

To remove a profile:

```
bebox profile remove
```

Then in the console a simple wizard appear for selecting the profile to remove from the available profiles.

To list profiles:

```
bebox profile list
```

**We recommend to use our default profiles (fundamental, users, security) for steps (0, 1, 3), but you can edit or delete them under your own risk**

**Important: Remember that you need to write/edit the puppet code for the profiles to work (specially step-2 that has no defaults); also you have to write/edit the Puppetfile template created to add modules that your profile use; additionally if you call hiera data from a profile you need to add them in the hiera/data/<data>.yaml file in the structure created (see Hiera part below)**


####Associate roles and profiles

This add/remove a profile to a role.

To add a profile to a role:

```
bebox role add_profile
```

Then in the console a simple wizard appear for selecting the role and profile to add.

To remove a profile from a role:

```
bebox role remove_profile
```

Then in the console a simple wizard appear for selecting the role and profile to remove.

To list profiles configured in a role:

```
bebox role list_profiles ROLE
```

####Associate nodes and roles

This change the role associated with a specific node.

To set the role for a specific node:

```
bebox node set_role [--environment ENVIRONMENT]
```

Then in the console a simple wizard appear for selecting the node and role to set.
By default if an *ENVIRONMENT* is not specified the default will be **vagrant**.


###Hiera

If you use hiera data from your profiles, you can add them to the appropiate file in the file structure shown below:

```
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
           └── Puppetfile (Automatically generated by the bebox tool in every apply)
```

The Number-[step] correspond to the step-[Number] in the provision steps phase. For example **0-fundamental** correspond to **step-0** option.

To add hiera data you need to edit any of the **[node].yaml**, **[environment].yaml**, **common.yaml**.
[node]: correspond to the hiera file for the node hostname (Ex. node0.server1.com.yaml).
[environment]: correspond to the hiera file for the node hostname (Ex. vagrant.yaml, production.yaml).


Development
-----------

To use the project in development mode, you need to do this:

* Clone bebox from the repository.
```
git clone ssh://git@codescrum.repositoryhosting.com/codescrum/bebox.git
```
* Make
```
bundle install
```
* Generate the gem package
```
rake package
```
* Make a tmp directory inside bebox folder
```
mkdir tmp
cd tmp
```
* Execute the project creation command preceded by **bundle exec**
```
bundle exec bebox new PROJECT
```
* Enter to the project created
```
cd PROJECT
```
* Add to the **Gemfile** the line
```
gem 'bebox', :path => "BEBOX_PATH_IN_YOUR_PC/pkg"
```
* Execute any project commands preceded by **bundle exec**
```
bundle exec bebox environment
```

Tests
-----

Before run tests you need to configure the IP address for vagrant machine. To do this create the file *spec/support/config_specs.yaml* from the *spec/support/config_specs.yaml.example* and configure a local newtwork IP free address to use.

By project's nature the specs must be run in order. To do this all specs has a 'Test XX:' naming convention. If you want to run all tests in order we have a ordered_phases_spec.rb file than you can run with.

```
rspec spec/ordered_phases_spec.rb
```

Maybe it would take a large time because it creates a vagrant machine and do a basic provision downloading packages and installing them in the machine.

**Important: You need to have the [ubuntu-server-12042-x64-vbox4210-nocm.box](http://puppet-vagrant-boxes.puppetlabs.com/ubuntu-server-12042-x64-vbox4210-nocm.box) in the bebox root folder to run the tests**
