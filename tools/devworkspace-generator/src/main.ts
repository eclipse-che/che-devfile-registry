/**********************************************************************
 * Copyright (c) 2022 Red Hat, Inc.
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 ***********************************************************************/

import * as axios from 'axios';
import * as fs from 'fs-extra';
import { Generate } from './generate';
import { GithubResolver } from './github/github-resolver';
import * as jsYaml from 'js-yaml';
import { InversifyBinding } from './inversify/inversify-binding';
import { UrlFetcher } from './fetch/url-fetcher';
import { PluginRegistryResolver } from './plugin-registry/plugin-registry-resolver';
import { V1alpha2DevWorkspaceSpecTemplate } from '@devfile/api';
import { DevfileContext } from './api/devfile-context';

export class Main {
  /**
   * Default constructor.
   */
  constructor() {
    // no-op
  }
  // Generates a devfile context object based on params
  public async generateDevfileContext(params: {
    devfilePath?: string;
    devfileUrl?: string;
    devfileContent?: string;
    outputFile?: string;
    editorPath?: string;
    pluginRegistryUrl?: string;
    editorEntry?: string;
    projects: { name: string; location: string }[];
  }): Promise<DevfileContext> {
    let { devfilePath, devfileUrl, outputFile, editorPath, pluginRegistryUrl, editorEntry, projects } = params;

    if (!editorPath && !editorEntry) {
      throw new Error('missing editorPath or editorEntry');
    }
    if (!devfilePath && !devfileUrl && !params.devfileContent) {
      throw new Error('missing devfilePath or devfileUrl or devfileContent');
    }
    if (editorEntry && !pluginRegistryUrl) {
      pluginRegistryUrl = 'https://eclipse-che.github.io/che-plugin-registry/main/v3';
      console.log(`No plug-in registry url. Setting to ${pluginRegistryUrl}`);
    }

    const axiosInstance = axios.default;
    const inversifyBinbding = new InversifyBinding();
    const container = await inversifyBinbding.initBindings({
      pluginRegistryUrl,
      axiosInstance,
    });
    container.bind(Generate).toSelf().inSingletonScope();

    let devfileContent;
    let editorContent;

    // gets the github URL
    if (devfileUrl) {
      const githubResolver = container.get(GithubResolver);
      const githubUrl = githubResolver.resolve(devfileUrl);
      // user devfile
      devfileContent = await container.get(UrlFetcher).fetchText(githubUrl.getContentUrl('devfile.yaml'));

      // load content
      const devfileParsed = jsYaml.load(devfileContent);

      // is there projects in the devfile ?
      if (devfileParsed && !devfileParsed.projects) {
        // no, so add the current project being cloned
        devfileParsed.projects = [
          {
            name: githubUrl.getRepoName(),
            git: {
              remotes: { origin: githubUrl.getCloneUrl() },
              checkoutFrom: { revision: githubUrl.getBranchName() },
            },
          },
        ];
      }
      // get back the content
      devfileContent = jsYaml.dump(devfileParsed);
    } else if (devfilePath) {
      devfileContent = await fs.readFile(devfilePath);
    } else {
      devfileContent = params.devfileContent;
    }

    // enhance projects
    devfileContent = this.replaceIfExistingProjects(devfileContent, projects);

    if (editorEntry) {
      // devfile of the editor
      const editorDevfile = await container.get(PluginRegistryResolver).loadDevfilePlugin(editorEntry);
      editorContent = jsYaml.dump(editorDevfile);
    } else {
      editorContent = await fs.readFile(editorPath);
    }

    const generate = container.get(Generate);
    return generate.generate(devfileContent, editorContent, outputFile);
  }

  // Update project entry based on the projects passed as parameter
  public replaceIfExistingProjects(devfileContent: string, projects: { name: string; location: string }[]): string {
    // do nothing if no override
    if (projects.length === 0) {
      return devfileContent;
    }
    const devfileParsed: V1alpha2DevWorkspaceSpecTemplate = jsYaml.load(devfileContent);

    if (!devfileParsed || !devfileParsed.projects) {
      return devfileContent;
    }
    devfileParsed.projects = devfileParsed.projects.map(project => {
      const userProjectConfiguration = projects.find(p => p.name === project.name);
      if (userProjectConfiguration) {
        if (userProjectConfiguration.location.endsWith('.zip')) {
          // delete git section and use instead zip
          delete project.git;
          project.zip = { location: userProjectConfiguration.location };
        } else {
          project.git.remotes.origin = userProjectConfiguration.location;
        }
      }
      return project;
    });
    return jsYaml.dump(devfileParsed);
  }

  async start(): Promise<boolean> {
    let devfilePath: string | undefined;
    let devfileUrl: string | undefined;
    let outputFile: string | undefined;
    let editorPath: string | undefined;
    let pluginRegistryUrl: string | undefined;
    let editorEntry: string | undefined;
    const projects: { name: string; location: string }[] = [];

    const args = process.argv.slice(2);
    args.forEach(arg => {
      if (arg.startsWith('--devfile-path:')) {
        devfilePath = arg.substring('--devfile-path:'.length);
      }
      if (arg.startsWith('--devfile-url:')) {
        devfileUrl = arg.substring('--devfile-url:'.length);
      }
      if (arg.startsWith('--plugin-registry-url:')) {
        pluginRegistryUrl = arg.substring('--plugin-registry-url:'.length);
      }
      if (arg.startsWith('--editor-entry:')) {
        editorEntry = arg.substring('--editor-entry:'.length);
      }
      if (arg.startsWith('--editor-path:')) {
        editorPath = arg.substring('--editor-path:'.length);
      }
      if (arg.startsWith('--output-file:')) {
        outputFile = arg.substring('--output-file:'.length);
      }
      if (arg.startsWith('--project.')) {
        const name = arg.substring('--project.'.length, arg.indexOf('='));
        let location = arg.substring(arg.indexOf('=') + 1);
        location = location.replace('{{_INTERNAL_URL_}}', '{{ INTERNAL_URL }}');

        projects.push({ name, location });
      }
    });

    try {
      if (!editorPath && !editorEntry) {
        throw new Error('missing --editor-path: or --editor-entry: parameter');
      }
      if (!devfilePath && !devfileUrl) {
        throw new Error('missing --devfile-path: or --devfile-url: parameter');
      }
      if (!outputFile) {
        throw new Error('missing --output-file: parameter');
      }
      await this.generateDevfileContext({
        devfilePath,
        devfileUrl,
        editorPath,
        outputFile,
        pluginRegistryUrl,
        editorEntry,
        projects,
      });
      return true;
    } catch (error) {
      console.error('stack=' + error.stack);
      console.error('Unable to start', error);
      return false;
    }
  }
}
