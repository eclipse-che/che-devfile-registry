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
  V1alpha2DevWorkspace,
  V1alpha2DevWorkspaceSpecContributions,
  V1alpha2DevWorkspaceSpecTemplateComponents,
  V1alpha2DevWorkspaceTemplate,
  V1alpha2DevWorkspaceTemplateSpec,
} from '@devfile/api';
import { injectable, inject } from 'inversify';
import * as jsYaml from 'js-yaml';
import * as fs from 'fs-extra';
import { DevfileContext } from './api/devfile-context';
import { DevContainerComponentFinder } from './devfile/dev-container-component-finder';

@injectable()
export class Generate {
  static readonly MERGE_CONTRIBUTION = 'controller.devfile.io/merge-contribution';

  @inject(DevContainerComponentFinder)
  private devContainerComponentFinder: DevContainerComponentFinder;

  async generate(devfileContent: string, editorContent: string, outputFile?: string): Promise<DevfileContext> {
    const context = await this.generateContent(devfileContent, editorContent);

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

  async generateContent(devfileContent: string, editorContent: string): Promise<DevfileContext> {
    const devfile = jsYaml.load(devfileContent);

    // const originalDevfile = Object.assign({}, devfile);
    // sets the suffix to the devfile name
    const suffix = devfile.metadata.name || '';

    // devfile of the editor
    const editorDevfile = jsYaml.load(editorContent);

    // transform it into a devWorkspace template
    const metadata = editorDevfile.metadata;
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
    const devfileMetadata = devfile.metadata;
    const devfileCopy = Object.assign({}, devfile);
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
        template: devfileCopy,
        contributions: [editorSpecContribution],
      },
    };

    // for now the list of devWorkspace templates is only the editor template
    const devWorkspaceTemplates = [editorDevWorkspaceTemplate];

    const context = {
      devfile,
      devWorkspace,
      devWorkspaceTemplates,
      suffix,
    };

    // grab container where to inject controller.devfile.io/merge-contribution attribute
    let devContainer: V1alpha2DevWorkspaceSpecTemplateComponents = await this.devContainerComponentFinder.find(context);

    // add attributes
    let devContainerAttributes = devContainer.attributes;
    if (!devContainerAttributes) {
      devContainerAttributes = {};
      devContainerAttributes[Generate.MERGE_CONTRIBUTION] = true;
      devContainer.attributes = devContainerAttributes;
    } else {
      devContainerAttributes[Generate.MERGE_CONTRIBUTION] = true;
    }

    return context;
  }
}
