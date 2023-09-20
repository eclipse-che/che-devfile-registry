/**********************************************************************
 * Copyright (c) 2022 Red Hat, Inc.
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 ***********************************************************************/

import {
  V221Devfile,
  V221DevfileMetadata,
  V1alpha2DevWorkspace,
  V1alpha2DevWorkspaceMetadata,
  V1alpha2DevWorkspaceSpecContributions,
  V1alpha2DevWorkspaceTemplate,
  V1alpha2DevWorkspaceTemplateSpec,
  V221DevfileStarterProjects,
} from '@devfile/api';
import { injectable, inject } from 'inversify';
import * as jsYaml from 'js-yaml';
import * as fs from 'fs-extra';
import { DevfileContext } from './api/devfile-context';
import { DevContainerComponentFinder } from './devfile/dev-container-component-finder';

type DevfileLike = V221Devfile & {
  metadata: V221DevfileMetadata & {
    generateName?: string;
  };
};

@injectable()
export class Generate {
  @inject(DevContainerComponentFinder)
  private devContainerComponentFinder: DevContainerComponentFinder;

  async generate(
    devfileContent: string,
    editorContent: string,
    outputFile?: string,
    injectDefaultComponent?: string,
    defaultComponentImage?: string
  ): Promise<DevfileContext> {
    const context = await this.generateContent(
      devfileContent,
      editorContent,
      injectDefaultComponent,
      defaultComponentImage
    );

    // write the result
    if (outputFile) {
      // write templates and then DevWorkspace in a single file
      const allContentArray = context.devWorkspaceTemplates.map(template => jsYaml.dump(template));
      allContentArray.push(jsYaml.dump(context.devWorkspace));

      const generatedContent = allContentArray.join('---\n');

      await fs.writeFile(outputFile, generatedContent, 'utf-8');
    }

    console.log(`DevWorkspace ${context.devWorkspaceTemplates[0].metadata.name} was generated.`);
    return context;
  }

  async generateContent(
    devfileContent: string,
    editorContent: string,
    injectDefaultComponent?: string,
    defaultComponentImage?: string
  ): Promise<DevfileContext> {
    const devfile = jsYaml.load(devfileContent);

    // const originalDevfile = Object.assign({}, devfile);
    // sets the suffix to the devfile name
    const suffix = devfile.metadata.name || '';

    // devfile of the editor
    const editorDevfile = jsYaml.load(editorContent);

    // transform it into a devWorkspace template
    const metadata = this.createDevWorkspaceMetadata(editorDevfile);
    // add sufix
    metadata.name = `${metadata.name}-${suffix}`;
    delete editorDevfile.metadata;
    delete editorDevfile.schemaVersion;
    const editorDevWorkspaceTemplate: V1alpha2DevWorkspaceTemplate = {
      apiVersion: 'workspace.devfile.io/v1alpha2',
      kind: 'DevWorkspaceTemplate',
      metadata,
      spec: editorDevfile as V1alpha2DevWorkspaceTemplateSpec,
    };

    // transform it into a devWorkspace
    const devfileMetadata = this.createDevWorkspaceMetadata(devfile, true);
    const devfileCopy: V221Devfile = Object.assign({}, devfile);
    delete devfileCopy.schemaVersion;
    delete devfileCopy.metadata;
    const editorSpecContribution: V1alpha2DevWorkspaceSpecContributions = {
      name: 'editor',
      kubernetes: {
        name: editorDevWorkspaceTemplate.metadata.name,
      },
    };
    const devWorkspace: V1alpha2DevWorkspace = {
      apiVersion: 'workspace.devfile.io/v1alpha2',
      kind: 'DevWorkspace',
      metadata: devfileMetadata,
      spec: {
        started: true,
        routingClass: 'che',
        template: devfileCopy,
        contributions: [editorSpecContribution],
      },
    };

    // if the devfile has a starter project, we use it for the devWorkspace
    if (devfileCopy.starterProjects && devfileCopy.starterProjects.length > 0) {
      devWorkspace.spec.template.attributes = {
        'controller.devfile.io/use-starter-project': devfileCopy.starterProjects[0].name,
      };
    }

    // for now the list of devWorkspace templates is only the editor template
    const devWorkspaceTemplates = [editorDevWorkspaceTemplate];

    const context = {
      devfile,
      devWorkspace,
      devWorkspaceTemplates,
      suffix,
    };

    // find devContainer component, add a default one if not found
    await this.devContainerComponentFinder.find(context, injectDefaultComponent, defaultComponentImage);

    return context;
  }

  private createDevWorkspaceMetadata(devfile: DevfileLike, addDevfileContent = false): V1alpha2DevWorkspaceMetadata {
    const devWorkspaceMetadata = {} as V1alpha2DevWorkspaceMetadata;
    const devfileMetadata = devfile.metadata;

    if (devfileMetadata.name) {
      devWorkspaceMetadata.name = devfileMetadata.name;
    }
    if (devfileMetadata.generateName) {
      devWorkspaceMetadata.generateName = devfileMetadata.generateName;
    }
    if (addDevfileContent) {
      devWorkspaceMetadata.annotations = {
        'che.eclipse.org/devfile': jsYaml.dump(devfile),
      };
    }

    return devWorkspaceMetadata;
  }
}
