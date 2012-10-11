# Teletortoise

* An experimental version of NetLogo that runs in-browser
* Structured in such a way that remote NetLogo workspaces run on the host server and feed NetLogo information to browser-based clients
* Utilizes the Play 2.0.x web framework
* Server side: Uses Scala to interface with a 'netlogo.jar' to provide headless workspaces
* Client side: Uses CoffeeScript to define client behavior, whilst using HTML and CSS to define the visual structure

# Installing

* [Obtain a 2.0.x release of the Play framework](http://www.playframework.org/download)
* Download the source from this very repository

# Running Locally

* In your terminal, navigate into the root source folder and run the `play` command
* Run the command `run <desired port number>`
* Open your browser and connect to the URL `http://localhost:<desired port number from above>`
  * __Note:__ This will take a while the first time you try to connect.  This is because Play does not compile up-to-date sources until they are requested.  (If you would like to force compilation ahead of time, you can use the `compile` command in the Play console.)  The upshot of this compilation strategy is that Play servers rarely need to be restarted during development, because Scala/Java/CoffeeScript sources are always recompiled when newer versions are available.

# Running Remotely

You may want to put this up onto a remote web host for some reason or another.  However, this application uses Web Sockets, and many popular hosts do not support Web Sockets at the moment.  Here is the list of known suitable hosts for this application:

* dotCloud

# Running on dotCloud

* [Create a dotCloud account](https://www.dotcloud.com/) and [get your command line all set up](http://docs.dotcloud.com/0.4/firststeps/install/#installation-instructions).
* Clone a copy of [this repo](https://github.com/mchv/play2-on-dotcloud) into a directory we'll call `$DC`
* Place your application source (as obtained in the __Running Locally__ section) into `$DC/application`
* From `$DC`, run the `dotcloud create <desired name>` command
* Run the `$DC push <desired name from above> --all` command
  * The `--all` is ___very___ important
* Wait 10ish minutes for the deployment to complete
* Connect to the URL that is eventually spit back at you

# Previous Influences

* [Seth Tisue's Wolf](https://github.com/SethTisue/Wolf)
* [Philip Woods's node.js Web Client](https://github.com/NetLogo/NetLogo-Web-Client)
* [NetLogo](https://github.com/NetLogo/NetLogo)
