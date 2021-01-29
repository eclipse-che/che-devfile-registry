<div align="center">
<img src="https://raw.githubusercontent.com/eclipse/che/assets/eclipseche.png" alt="Eclipse Che - Eclipse Next-Generation IDE" width="500"/>

<br />

<img src="https://camo.githubusercontent.com/e58fd7c051c2e9a9bb15ded65df3413770bbbfd2ffec6ceba290f515b89ffe4d/68747470733a2f2f64657369676e2e6a626f73732e6f72672f717561726b75732f6c6f676f2f66696e616c2f504e472f717561726b75735f6c6f676f5f686f72697a6f6e74616c5f7267625f3132383070785f64656661756c742e706e67" alt="Quarkus - Supersonic Subatomic Java" width="500"/>


</div>

# Welcome your `Quarkus` Eclipse Che workspace
Congratulations! You have started a Che workspace with the Quarkus Getting started sample. You are all set to code, debug, compile and test in a production-like environment. Let’s start!

The guide is interactive. You can click on the below links to open files or start the predefined commands.

Powered by [Eclipse Che](https://www.eclipse.org/che/) and [VSCode Didact](https://github.com/redhat-developer/vscode-didact).

## Quarkus-quickstarts / getting-started
This Che workspace clones a copy of the `getting-started` project from the [quarkus-quickstarts](https://github.com/quarkusio/quarkus-quickstarts.git) git repository.
The `getting-started` project is a simple Hello World JAX-RS application. Refer to the [getting-started Quarkus guide](https://quarkus.io/guides/getting-started) to know more about this application.

## Start Quarkus in devmode
The Quarkus development mode enables hot deployment with background compilation. It also listen for a debugger on port `5005`. You can find more informations about Quarkus development mode in this guide: https://quarkus.io/guides/getting-started#development-mode.

This workspace comes with a predefined command to start the Quarkus app in devmode.

Run the `Start Development mode (Hot reload + debug)` command:

- using this direct link [Start Development mode (Hot reload + debug)](didact://?commandId=workbench.action.tasks.runTask&text=Start%20Development%20mode%20%28Hot%20reload%20%2B%20debug%29)
- or from the `My Workspace` view on the right [toggle](didact://?commandId=plugin.view-container.my-workspace.toggle)
- or from the command palette `F1` > [Run task...](didact://?commandId=workbench.action.tasks.runTask)


Once the Quarkus server is started, the Che workspace will suggest you to open the application URL. Choose `Open in Preview` . You should see `hello che-user` displayed in the Preview panel.


## Open GreetingService.java to make some live changes
1. Open the file [GreetingService.java](didact://?commandId=vscode.open&projectFilePath=quarkus-quickstarts%2Fgetting-started%2Fsrc%2Fmain%2Fjava%2Forg%2Facme%2Fgetting%2Fstarted%2FGreetingService.java&number=2).
2. You may need to wait for the Quarkus extension to be activated (see status bar).
3. In [GreetingService.java](didact://?commandId=vscode.open&projectFilePath=quarkus-quickstarts%2Fgetting-started%2Fsrc%2Fmain%2Fjava%2Forg%2Facme%2Fgetting%2Fstarted%2FGreetingService.java&number=2) set the name in uppercase using the auto complete (`Ctrl-Space`).
   ```
   public String greeting(String name) {
     return "hello " + name.toUpperCase();
   }
   ```
4. From the Preview panel, refresh the page. `hello CHE-USER` should be display instead of `hello che-user`.

## Add a breakpoint/start debugging, live change variable
Let's try to debug the application:

1. Start the debugger by hitting `F5` or clicking [here](didact://?commandId=workbench.action.debug.start)
2. Open the file [GreetingResource.java](didact://?commandId=vscode.open&projectFilePath=quarkus-quickstarts%2Fgetting-started%2Fsrc%2Fmain%2Fjava%2Forg%2Facme%2Fgetting%2Fstarted%2FGreetingResource.java&number=2).
3. Add a break point at line 21
    ```
    return service.greeting(name);
    ```
4. From the Preview panel, refresh the page. The debugger should stop at the breakpoint.
5. From the Debug panel [toggle](didact://?commandId=debug%3Atoggle), Select `Variables` > `Local` and the `name` variable with the value `che-user`. Right click and select `set value`. Replace `che-user` with `world`.
6. Hit `F5` to continue or click [here](didact://?commandId=workbench.action.debug.continue)
7. The preview pane should display `hello world`
8. Hit `Shift + F5` or click [here](didact://?commandId=workbench.action.debug.stop) to stop the debugger.
9. Open the bottom tab `Start Development mode (Hot reload + debug)`(the one with the quarkus logs). Hit `Ctrl + c` to stop the quarkus server.

## Building a native executable
Quarkus applications can be compiled as a native executable to be packaged in a container. You can find more informations in this guide: https://quarkus.io/guides/building-native-image.

Let's produce the native executable and run it with these predefined commands:
1. Produce the native application with the predefined command [Package Native](didact://?commandId=workbench.action.tasks.runTask&text=Package%20Native). The compilation speed depends on the underlining machine resources.

2. Run native app with the predefined command [Start Native](didact://?commandId=workbench.action.tasks.runTask&text=Start%20Native). Notice how fast it was to start the native application! 

## Behind the scene: Che workspace is composed of containers
Quarkus requires Java and GraalVM (or Mandrel) to produce the native executable.

But, wait a minute ... you have not installed anything to produce the native executable. This is because this workspace has been designed with a dedicated container to build a Quarkus application. Let's dive in.

Open the `My Workspace` view on the right [toggle](didact://?commandId=plugin.view-container.my-workspace.toggle) and observe the containers running inside this workspace.

- `centos-quarkus-maven` is a container providing Maven, Java and GraalVM. The `Package Native` predefined command is executed in this container.
- `ubi-minimal` is a container with the minimal dependencies to run a Quarkus native executable. It would using the same container image that will be used in a production environment. The predefined command `Start Native` is executed in this container.

You can also have a terminal access to each of the container.

## Eclipse Che workspaces: devfile.yaml
This workspace has been generated from a `devfile`: a Yaml file describing
- the projects to clone,
- the tools to assist you when coding your application (plugins)
- the containers to build and run your application
- some predefine commands to perform the common tasks of your project.

You can export the devfile being used for a workspace with the command [Workspace: Save Workspace As ...](didact://?commandId=che.saveWorkspaceAs). Save the file in the `/projects` folder and open it.

The same devfile could be reused to regenerate a clone of this workspace. It would be generated in a new, disposable and isolated workspace. Make your own customisation, copy the content and create a new workspace from it using the `Create Workspace` button in the Eclipse Che dashboard or navigation bar (yellow button at the top left). 

## Get involved
Thanks for trying Eclipse Che.

We love to hear from users and developers. Here are the various ways to get in touch with us:
* **Support:** You can ask questions, report bugs, and request features using [GitHub issues](https://github.com/eclipse/che/issues).
* **Public Chat:** Join the public [eclipse-che](https://mattermost.eclipse.org/eclipse/channels/eclipse-che) Mattermost channel to discuss with community and contributors.
* **Twitter:** [@eclipse_che](https://twitter.com/eclipse_che)
* **Mailing List:** [che-dev@eclipse.org](https://accounts.eclipse.org/mailing-list/che-dev)
* **Weekly Meetings:** Join us in our [Che community meeting](https://github.com/eclipse/che/wiki/Che-Dev-Meetings) every monday.
