# Teletortoise

* An experimental version of NetLogo that displays in-browser
* Structured in such a way that a remote NetLogo model runs on the server and feeds NetLogo information to browser-based clients
* Utilizes the Play 2.0.x web framework
* Server side: Uses Scala to interface with a 'NetLogo.jar' to provide headless workspaces
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

You may want to put Teletortoise up onto a remote web host for some reason or another.  However, Teletortoise uses Web Sockets, and many popular hosts do not support Web Sockets at the moment.  On top of that, there are also several other things to be taken into consideration when launching Teletortoise remotely.  Please see [this page](https://github.com/NetLogo/Teletortoise/wiki/Web-Host-Survey) for a comparison of different web hosting choices considered for Teletortoise.

# Accessing the "Official" Remote Instance

Currently, the official test server is hosted by [Linode](http://www.linode.com/), and is accessible [here](http://li425-91.members.linode.com:9000).  Please view [this page](https://github.com/NetLogo/Teletortoise/wiki/Interacting-with-the-Linode-Server) for instructions of how to access the Play server and code running on the Linode instance.

# Previous Influences

* [Seth Tisue's Wolf](https://github.com/SethTisue/Wolf)
* [Philip Woods's node.js Web Client](https://github.com/NetLogo/NetLogo-Web-Client)
* [NetLogo](https://github.com/NetLogo/NetLogo)
