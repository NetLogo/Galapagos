# Galapagos: the NetLogo Web Simulation View and Website

**NetLogo Web** is a browser-based version of [NetLogo](https://www.netlogo.org/), the multi-agent programmable modeling environment from the Center for Connected Learning and Computer-Based Modeling at Northwestern University. It runs entirely in the browser, no plugins or installation required.

## Using NetLogo Web

If you're looking to run models or write NetLogo code, you probably don't need this repository:

- **[netlogoweb.org](https://netlogoweb.org)**: run NetLogo Web in your browser, browse the models library, read the docs, and find answers in the FAQ
- **[netlogo.org](https://www.netlogo.org)**: download desktop NetLogo, access full documentation, find curriculum resources, and explore the community models library

## About This Repository

Galapagos is the [Play Framework](https://www.playframework.com/) application that serves NetLogo Web. It handles HTTP routing, the built-in models library, and delegates model compilation to the [Tortoise](https://github.com/NetLogo/Tortoise) JVM compiler, which translates NetLogo code into JavaScript that runs in the browser.

The frontend is written in CoffeeScript and uses [Ractive.js](https://ractive.js.org/) for the IDE widgets (buttons, sliders, plots, monitors, etc.).

Related projects:

- **[Tortoise](https://github.com/NetLogo/Tortoise)**: the NetLogo-to-JavaScript compiler and JavaScript runtime engine that power NetLogo Web
- **[NetLogo](https://github.com/NetLogo/NetLogo)**: the desktop NetLogo application, which shares its basic file reader and parser with Tortoise

## Contributing

- **[NetLogo Web Contributing Guide](https://github.com/NetLogo/Tortoise/wiki/CONTRIBUTING)**: full guidelines: git workflow, testing, publishing Tortoise changes, and code style (CoffeeScript, CSS, Scala)
- **[Galapagos wiki](https://github.com/NetLogo/Galapagos/wiki)**: project-specific docs: local setup, architecture, UI/CSS conventions, release process, and updating the models library
