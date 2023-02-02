## DevWorkspace Generator
The library is used by Devfile registry component to generate the DevWorkspace components and DevWorkspace templates.

## How to use the library
The library could be used as a standalone library.

```
USAGE
    $ node lib/entrypoint.js [OPTIONS]

OPTIONS
      --devfile-path    path to the devfile.yaml file
      --devfile-url     URL to the git repository that contains devfile.yaml 
      --plugin-registry-url URL to the plugin registry that contains an editor's definition
      --editor-entry    editor's ID 
      --editor-path:    path to the editor's devfile.yaml file
      --output-file path to the file where the generated content will be stored
      --project.    describes project entry

EXAMPLE

    $ node lib/entrypoint.js --devfile-url:https://github.com/che-samples/java-spring-petclinic/tree/main --editor-entry:che-incubator/che-code/insiders --plugin-registry-url:https://che-plugin-registry-main.surge.sh/v3/ --output-file:/tmp/all-in-one.yaml`
```

The file `/tmp/all-in-one.yaml` contains a DevWorkspace based on the repository devfile and a Che-Code DevWorkspaceTemplate.
If DevWorkspace engine is available on the cluster, the following command will create a DevWorkspace:

`$ kubectl apply -f /tmp/all-in-one.yaml`
