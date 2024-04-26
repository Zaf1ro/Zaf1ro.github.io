## ICC - IBM Customer Connect
ICC is an externally facing web site that facilitates secure collaboration, workflow, and information publication with select customers and partners.
External portal for IBM clients, partners, and IBM'ers, providing a broad suite of 15+ web based e-business applications across client engagement lifecycle.​
* At rest and in transit encryption​
* Collaboration Workspaces​
* External clients with secure large file exchange​
* Discussion Forums​
* Customer Contracts (e.g. CCA)
* Customers: Primarily STG and MD business units and Research, GBS, GTS, and SWG
* ~1,200 Users (500 Internal, ~700 External)
* ~10,000 hits per day
* Process 1900~ Shipment Alerts per month​
* Process ~3600 automated shipments per month  (~120/day)
* ~7.5M line of codes

### Deployment Workflow
* Unit: Developer writes the code using Eclipse IDE and compiles it in workspace. After successful compilation test, unit test and, vulnerability scan the developer commits the code into the designated repositories in Enterprise Github. Developer make sure no Critical / High vulnerability alerts before committing code using App Scan & CONTRAST plugin in eclipse IDE
* Integrated Build / Deploy: Jenkins CICD
* Test: Test team tests the function in fix system according to the test case in test documentation
* Fixpack Review: Deployment Lead review the status in scrum call . Deployment lead / Scrum masters / BA’s / Developers / Testers attend this call. Reviewed for resources required / Special instructions /Vulnerability scan results (No Critical / High)/ Code move to Test env / GDPR / PI impacts

### Components
#### Access Management
Control access to functions and content on IBM Customer Connect. Require IBM ID, Authentication, Access Authorization, Employment Verfication, Access Audit, Records, Application Health Check, Privileged User Management
* Request Entitlement: Business Area and Company Name
* Check my information:
    * Basic Information: IBM ID, Name, Email Address, Company Name, Manager
    * list of all the entitlements that this account currently has
    * list of users for whom you are Manager or POC
    * list of all entitlements for this account that are pending approval

#### CollabCenter
ICC Collaboration Center is a secure Web portal that allows employees and clients to collaborate on proposals and projects.
* Home Page:
    * Create a workspace: Only IBM employees will get the option to create a workspace
    * Request access to a workspace
* Document Component:
    * Create/Update/Delete Folder
    * Add Document
    * List all documents
    * Access History
* Document Detail:
    * Name
    * Description
    * Upload file
    * Expiration Date
    * Security classification - team member
    * Edit/Read access: Group / User list
    * Email notification list: Group / User list
* Issue Management:
    * Submit a new issue
    * Manage issue type
    * Manage custom fields
    * Manage issue subscription
* Issue Detail:
    * Title
    * Description
    * Issue Type -> filter for issue list
    * Due date
    * Attachment
    * Custom Field
    * Notification list: Group / User list
* Team:
    * Export team member
    * Add/invite team member
    * Remove team member
    * View/Create Group
* Team member:
    * Username
    * User Id
    * Access Level
* Group Detail:
    * Group Name
    * Group Type -> Private/public
    * Group Security Classification -> All Team member / IBM Member only
    * Member list
* Generate Report

### Change History
* 2005: Create of Deployment Process for ICC/B2B apps

### Tools
* IDE: Eclipse
* Language: Java, SpringBoot, Spring, J2EE, JSF
* Web application server: Websphere Liberty
* MQ: MQSeries, now known as IBM MQ
* SFTP server
* Maven: Our property strategy has always been to use the PFT process (PropertyFileTool)  to do variable substitution. If you look in various property files in the ICCPropertiesProj you will find that the syntax myprop=${varname} is used. The varname is a master property which will be substituted both at maven build time and again when we massage/deploy the ears to a target environment. 
    * For local dev: create the icc/masterfiles directories, The contents of the BOX/ICC 2.0/secrets directory can be copied there
    * For non local deploys, we have a pre-deploy ear massaging process which we run. This will download the ear/version, unpack it, unpack the war, unzip the ICCPropertieProj.jar and then use the PFT tool to do essentially the same thing we do for our local with maven
* Jira: contains all of the documentation by sprint and application

### Projects
#### Migrate to IBM Hybrid CLOUD
* Project structure changes:
    * Move from Rational Team Concert (RTC) to Github:
        * RTC is not cloud native
        * RTC can only store all data into one single database
        * RTC is a suite of features that includes source control. Git only does source control
    * Create separate github repository for each service
    * Change stateful to stateless service
    * Parent pom holds all necessary base configuration and dependencies of a maven project. All service projects will be child projects of this parent. 
    * Implement gRPC for communication between each services
    * Move all config file to Cirrus Secrets(Secrets are bound to the specific cluster you select, and will give your applications access to environment variables at runtime.)
* Create Dockers image for Websphere Liberty server
    * install package, such openjdk, zip, unzip
    * copy certificate, config file, db2 jars, server xml
    * run shell script to download the ear and property file
    * copy all necessary files to /opt/ibm/wlp/bin 
    * run maven build and package
    * run websphere liberty server
* Create DB2 instance and IBM MQ on IBM Cloud

#### Upgrade Frontend from Northstar to Carbon Design System
* Challenge: We are mostly aligned with JSF and server side listeners to handle most of the actions / rerenders. The new approach uses client side REACT data-based components.
* Action:
    * Rewrite part of webpage which has less interaction with backend service from JSF to Carbon component
    * For some components with total different functionality: rewrite to react component, and adopt backend service, such as datatable
    * Hybrid migration: create a new project to carry a tag library of JSF Composite Components to help encapsulate the complexity of the individual input components, such as header, message, button, inputText, checkbox, select.
    * Stay with old design system if it's not external webpage


## Deemed Export Regulation
A Deemed Export is a foreign national working in the US. US regulations require identification, and traceability of deemed exports, as well as the projects and level of technology they have access to. The Export Regulations Compliance Tool provides for automatic collection of Visa Holder data, notifications to visa holders/managers/coworkers, and tracking of required compliance.

### Tech stack
* IDE: vscode
* Language: TypeScript
* Data Storage: Db2, MongoDB, Kafka

### Components
#### VisaHolder
* Serial Number
* Name
* Email
* Manager: Name, Serial, email
* Visa Type
* Date of Hire
* Division/Department/Site
* Control Program
* Country
* Attachment
* Job Description
* Review History
* Update History

#### Checklist
* Employee Type
* System access, database access
* Meeting title, owner and date
* Presentation topic, date, presenter

#### Background Job 
* retrieve new visa holder from db2 and fill up with information, notify manager and ERC(export regulation coondinator)
* check if a checklist has been completed: notify ERC
* check if information of existing visaholder had been updated
* Send year review for each visaholder to their manager

### Components
#### Frontend Proxy
* Nginx
    * load balancing: proxy HTTP Traffic to a Group of Servers
    * cache static resource, including html, css, js
    * during request processing, make a subrequest to the internal authentication service
* Webpack
    * organize and bundle various assets such as HTML, JavaScript, CSS, images into a single output file

#### API Server
implement REST APIs


