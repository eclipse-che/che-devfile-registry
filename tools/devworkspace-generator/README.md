## DevWorkspace Generator
The library is used by Devfile registry component to generate the DevWorkspace components and DevWorkspace templates. It requires editor definitions from the 
[che-plugin-registry](https://github.com/eclipse-che/che-plugin-registry/).

## How to use the library
The library can be used as a standalone library.

```
USAGE
    $ node lib/entrypoint.js [OPTIONS]

OPTIONS
      --devfile-url:           URL to the git repository that contains devfile.yaml
            or
      --devfile-path:          path to the devfile.yaml file

      --plugin-registry-url:   URL to the plugin registry that contains editor definitions (devfile.yaml)
      --editor-entry:          editor ID, found on the <plugin-registry-url>, to resolve the devfile.yaml
            or
      --editor-path:           local file path of the editor devfile.yaml

      --output-file:           local file path for the generated devworkspace yaml 

      --project.<project-name> local file path for the sample project zip (for airgapped/offline registry builds)

      --injectDefaultComponent: inject a default dev container component if no component is defined in the devfile and it doesn't provide a parent, the value can be true or false, default is false

      --defaultComponentImage: image to use for the default dev container component that will be injected if no componetn is defined in the devfile and it doesn't provide a parent devfile, default is quay.io/devfile/universal-developer-image:ubi8-latest

EXAMPLES

    # online example, using editor definition from https://che-plugin-registry-main.surge.sh/

    $ node lib/entrypoint.js \
        --devfile-url:https://github.com/che-samples/java-spring-petclinic/tree/main \
        --plugin-registry-url:https://che-plugin-registry-main.surge.sh/v3/ \
        --editor-entry:che-incubator/che-code/latest \
        --output-file:/tmp/devworkspace-che-code-latest.yaml \
        --injectDefaultComponent:true \
        --defaultComponentImage:registry.access.redhat.com/ubi8/openjdk-11:latest

    # offline example with devfile.yaml files and zipped project available locally

    $ node lib/entrypoint.js \
        --devfile-path:/remote-source/python-hello-world/app/devfile.yaml \
        --editor-path:/build/plugins/che-incubator/che-code/latest/devfile.yaml \
        --output-file:./devfiles/python__python-hello-world/devworkspace-che-code-latest.yaml \
        --project.python-hello-world='{{_INTERNAL_URL_}}/resources/v2/python-hello-world.zip'

```

The output file `devworkspace-che-code-latest.yaml` contains a DevWorkspace based on the repository devfile and a Che-Code DevWorkspaceTemplate.

If the DevWorkspace engine is installed on the cluster, the following command will create a DevWorkspace:

`$ kubectl apply -f /tmp/devworkspace-che-code-latest.yaml`
