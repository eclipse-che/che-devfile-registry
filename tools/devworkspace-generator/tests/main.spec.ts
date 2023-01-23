/**********************************************************************
 * Copyright (c) 2022 Red Hat, Inc.
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 ***********************************************************************/
/* eslint-disable @typescript-eslint/no-explicit-any */
import 'reflect-metadata';

import { InversifyBinding } from '../src/inversify/inversify-binding';
import { Main } from '../src/main';
import fs from 'fs-extra';
import * as jsYaml from 'js-yaml';

describe('Test Main with stubs', () => {
  const FAKE_DEVFILE_PATH = '/my-fake-devfile-path';
  const FAKE_DEVFILE_URL = 'http://fake-devfile-url';
  const FAKE_EDITOR_PATH = '/my-fake-editor-path';
  const FAKE_OUTPUT_FILE = '/fake-output';
  const FAKE_PLUGIN_REGISTRY_URL = 'http://fake-plugin-registry-url';
  const FAKE_EDITOR_ENTRY = 'fake/editor';

  const originalConsoleError = console.error;
  const mockedConsoleError = jest.fn();

  const originalConsoleLog = console.log;
  const mockedConsoleLog = jest.fn();

  const generateMethod = jest.fn();
  const originalArgs = process.argv;
  const selfMock = {
    inSingletonScope: jest.fn(),
  };
  const toSelfMethod = jest.fn();
  const bindMock = {
    toSelf: toSelfMethod,
  };
  const generateMock = {
    generate: generateMethod as any,
  };

  const containerBindMethod = jest.fn();
  const containerGetMethod = jest.fn();
  const container = {
    bind: containerBindMethod,
    get: containerGetMethod,
  } as any;
  let spyInitBindings;

  const readFileSpy = jest.spyOn(fs, 'readFile');

  function initArgs(
    devfilePath: string | undefined,
    devfileUrl: string | undefined,
    editorPath: string | undefined,
    editorEntry: string | undefined,
    outputFile: string | undefined,
    pluginRegistryUrl: string | undefined
  ) {
    // empty args
    process.argv = ['', ''];
    if (devfilePath) {
      process.argv.push(`--devfile-path:${devfilePath}`);
    }
    if (devfileUrl) {
      process.argv.push(`--devfile-url:${devfileUrl}`);
    }
    if (editorEntry) {
      process.argv.push(`--editor-entry:${editorEntry}`);
    }
    if (editorPath) {
      process.argv.push(`--editor-path:${editorPath}`);
    }
    if (outputFile) {
      process.argv.push(`--output-file:${outputFile}`);
    }
    if (pluginRegistryUrl) {
      process.argv.push(`--plugin-registry-url:${pluginRegistryUrl}`);
    }
  }

  beforeEach(() => {
    console.error = mockedConsoleError;
    console.log = mockedConsoleLog;
  });

  afterEach(() => {
    console.error = originalConsoleError;
    console.log = originalConsoleLog;
  });

  describe('start', () => {
    beforeEach(() => {
      initArgs(FAKE_DEVFILE_PATH, undefined, FAKE_EDITOR_PATH, undefined, FAKE_OUTPUT_FILE, FAKE_PLUGIN_REGISTRY_URL);
      // mock devfile and editor
      readFileSpy.mockResolvedValueOnce('');
      readFileSpy.mockResolvedValueOnce('');

      spyInitBindings = jest.spyOn(InversifyBinding.prototype, 'initBindings');
      spyInitBindings.mockImplementation(() => Promise.resolve(container));
      toSelfMethod.mockReturnValue(selfMock), containerBindMethod.mockReturnValue(bindMock);
      containerGetMethod.mockReturnValueOnce(generateMock);
    });

    afterEach(() => {
      process.argv = originalArgs;
      jest.restoreAllMocks();
      jest.resetAllMocks();
    });

    test('success', async () => {
      process.argv.push('--project.foo=bar');
      const main = new Main();
      const returnCode = await main.start();
      expect(mockedConsoleError).toBeCalledTimes(0);

      expect(returnCode).toBeTruthy();
      expect(generateMethod).toBeCalledWith('', '', FAKE_OUTPUT_FILE);
    });

    test('success with custom devfile Url', async () => {
      const main = new Main();
      initArgs(undefined, FAKE_DEVFILE_URL, undefined, FAKE_EDITOR_ENTRY, FAKE_OUTPUT_FILE, FAKE_PLUGIN_REGISTRY_URL);
      containerGetMethod.mockReset();
      const githubResolverResolveMethod = jest.fn();
      const githubResolverMock = {
        resolve: githubResolverResolveMethod as any,
      };

      const getContentUrlMethod = jest.fn();
      const getCloneUrlMethod = jest.fn();
      const getBranchNameMethod = jest.fn();
      const getRepoNameMethod = jest.fn();

      const githubUrlMock = {
        getContentUrl: githubResolverResolveMethod as any,
        getCloneUrl: getCloneUrlMethod as any,
        getBranchName: getBranchNameMethod as any,
        getRepoName: getRepoNameMethod as any,
      };
      getContentUrlMethod.mockReturnValue('http://foo.bar');
      getCloneUrlMethod.mockReturnValue('http://foo.bar');
      getBranchNameMethod.mockReturnValue('my-branch');
      getRepoNameMethod.mockReturnValue('my-repo');
      githubResolverResolveMethod.mockReturnValue(githubUrlMock);
      containerGetMethod.mockReturnValueOnce(githubResolverMock);

      const urlFetcherFetchTextMethod = jest.fn();
      const urlFetcherMock = {
        fetchText: urlFetcherFetchTextMethod as any,
      };
      urlFetcherFetchTextMethod.mockReturnValueOnce('schemaVersion: 2.1.0');
      containerGetMethod.mockReturnValueOnce(urlFetcherMock);

      const loadDevfilePluginMethod = jest.fn();
      const pluginRegistryResolverMock = {
        loadDevfilePlugin: loadDevfilePluginMethod as any,
      };
      loadDevfilePluginMethod.mockReturnValue('');
      containerGetMethod.mockReturnValueOnce(pluginRegistryResolverMock);

      // last one is generate mock
      containerGetMethod.mockReturnValueOnce(generateMock);
      const returnCode = await main.start();
      expect(mockedConsoleError).toBeCalledTimes(0);
      expect(loadDevfilePluginMethod).toBeCalled();
      expect(urlFetcherFetchTextMethod).toBeCalled();

      expect(returnCode).toBeTruthy();

      const result = {
        schemaVersion: '2.1.0',
        projects: [
          {
            name: 'my-repo',
            git: {
              remotes: {
                origin: 'http://foo.bar',
              },
              checkoutFrom: {
                revision: 'my-branch',
              },
            },
          },
        ],
      };
      expect(generateMethod).toBeCalledWith(jsYaml.dump(result), "''\n", FAKE_OUTPUT_FILE);
    });

    test('editorEntry with default plugin registry URL', async () => {
      const main = new Main();
      initArgs(FAKE_DEVFILE_PATH, undefined, undefined, FAKE_EDITOR_ENTRY, FAKE_OUTPUT_FILE, undefined);
      await main.start();
      expect(mockedConsoleLog).toBeCalled();
      expect(mockedConsoleLog.mock.calls[0][0].toString()).toContain('No plug-in registry url. Setting to');

      // check plugin url is provided to initBindings
      expect(spyInitBindings.mock.calls[0][0].pluginRegistryUrl).toBe(
        'https://eclipse-che.github.io/che-plugin-registry/main/v3'
      );
    });

    test('missing devfile', async () => {
      const main = new Main();
      initArgs(undefined, undefined, FAKE_EDITOR_PATH, undefined, FAKE_OUTPUT_FILE, FAKE_PLUGIN_REGISTRY_URL);
      const returnCode = await main.start();
      expect(mockedConsoleError).toBeCalled();
      expect(mockedConsoleError.mock.calls[1][1].toString()).toContain('missing --devfile-path:');
      expect(returnCode).toBeFalsy();
      expect(generateMethod).toBeCalledTimes(0);
    });

    test('missing editor', async () => {
      const main = new Main();
      initArgs(FAKE_DEVFILE_PATH, undefined, undefined, undefined, FAKE_OUTPUT_FILE, FAKE_PLUGIN_REGISTRY_URL);

      const returnCode = await main.start();
      expect(mockedConsoleError).toBeCalled();
      expect(mockedConsoleError.mock.calls[1][1].toString()).toContain('missing --editor-path:');
      expect(returnCode).toBeFalsy();
      expect(generateMethod).toBeCalledTimes(0);
    });

    test('missing outputfile', async () => {
      const main = new Main();
      initArgs(FAKE_DEVFILE_PATH, undefined, FAKE_EDITOR_PATH, undefined, undefined, FAKE_PLUGIN_REGISTRY_URL);
      const returnCode = await main.start();
      expect(mockedConsoleError).toBeCalled();
      expect(mockedConsoleError.mock.calls[1][1].toString()).toContain('missing --output-file: parameter');
      expect(returnCode).toBeFalsy();
      expect(generateMethod).toBeCalledTimes(0);
    });

    test('error', async () => {
      jest.spyOn(InversifyBinding.prototype, 'initBindings').mockImplementation(() => {
        throw new Error('Dummy error');
      });
      const main = new Main();
      const returnCode = await main.start();
      expect(mockedConsoleError).toBeCalled();
      expect(returnCode).toBeFalsy();
      expect(generateMethod).toBeCalledTimes(0);
    });
  });

  describe('generateDevfileContext', () => {
    beforeEach(() => {
      spyInitBindings = jest.spyOn(InversifyBinding.prototype, 'initBindings');
      spyInitBindings.mockImplementation(() => Promise.resolve(container));
      toSelfMethod.mockReturnValue(selfMock), containerBindMethod.mockReturnValue(bindMock);
    });

    afterEach(() => {
      process.argv = originalArgs;
      jest.restoreAllMocks();
      jest.resetAllMocks();
    });

    test('missing editor', async () => {
      const main = new Main();
      let message: string | undefined;
      try {
        await main.generateDevfileContext({
          devfilePath: FAKE_DEVFILE_PATH,
          projects: [],
        });
        throw new Error('Dummy error');
      } catch (e) {
        message = e.message;
      }
      expect(message).toEqual('missing editorPath or editorEntry');
    });

    test('missing devfile', async () => {
      const main = new Main();
      let message: string | undefined;
      try {
        await main.generateDevfileContext({
          editorEntry: FAKE_EDITOR_ENTRY,
          projects: [],
        });
        throw new Error('Dummy error');
      } catch (e) {
        message = e.message;
      }
      expect(message).toEqual('missing devfilePath or devfileUrl or devfileContent');
    });

    test('success with custom devfile content', async () => {
      const main = new Main();
      containerGetMethod.mockReset();
      const loadDevfilePluginMethod = jest.fn();
      const pluginRegistryResolverMock = {
        loadDevfilePlugin: loadDevfilePluginMethod as any,
      };
      loadDevfilePluginMethod.mockReturnValue('');
      containerGetMethod.mockReturnValueOnce(pluginRegistryResolverMock);

      // last one is generate mock
      containerGetMethod.mockReturnValueOnce(generateMock);

      const devfileContent = jsYaml.dump({
        schemaVersion: '2.1.0',
        projects: [
          {
            name: 'my-repo',
            git: {
              remotes: {
                origin: 'http://foo.bar',
              },
              checkoutFrom: {
                revision: 'my-branch',
              },
            },
          },
        ],
      });

      await main.generateDevfileContext({
        devfileContent,
        outputFile: FAKE_OUTPUT_FILE,
        pluginRegistryUrl: FAKE_PLUGIN_REGISTRY_URL,
        editorEntry: FAKE_EDITOR_ENTRY,
        projects: [],
      });

      expect(mockedConsoleError).toBeCalledTimes(0);
      expect(loadDevfilePluginMethod).toBeCalled();
      expect(generateMethod).toBeCalledWith(devfileContent, "''\n", FAKE_OUTPUT_FILE);
    });
  });

  describe('replaceIfExistingProjects', () => {
    test('empty', async () => {
      const devfileContent = '';
      const projects = [];
      const main = new Main();
      const result = main.replaceIfExistingProjects(devfileContent, projects);
      expect(result).toBe('');
    });

    test('empty with user projects', async () => {
      const devfileContent = '';
      const projects = [
        {
          name: 'my-other-repo',
          location: 'http://my-location',
        },
      ];
      const main = new Main();
      const result = main.replaceIfExistingProjects(devfileContent, projects);
      expect(result).toBe('');
    });

    test('existing projects not matching', async () => {
      const initialProjects = [
        {
          name: 'my-repo',
          git: {
            remotes: {
              origin: 'http://my.origin',
            },
            checkoutFrom: {
              revision: 'my-branch',
            },
          },
        },
      ];

      const devfileContent = jsYaml.dump({
        projects: initialProjects,
      });
      const projects = [
        {
          name: 'my-other-repo',
          location: 'http://my-location',
        },
      ];
      const main = new Main();
      const result = main.replaceIfExistingProjects(devfileContent, projects);
      const devfileResult = jsYaml.load(result);
      expect(devfileResult.projects).toStrictEqual(initialProjects);
    });

    test('existing projects matching zip', async () => {
      const initialProjects = [
        {
          name: 'my-repo',
          git: {
            remotes: {
              origin: 'http://my.origin',
            },
            checkoutFrom: {
              revision: 'my-branch',
            },
          },
        },
      ];

      const devfileContent = jsYaml.dump({
        projects: initialProjects,
      });
      const projects = [
        {
          name: 'my-repo',
          location: 'http://my-location.zip',
        },
      ];
      const main = new Main();
      const result = main.replaceIfExistingProjects(devfileContent, projects);
      const devfileResult = jsYaml.load(result);

      const expectedProjects = [
        {
          name: 'my-repo',
          zip: {
            location: 'http://my-location.zip',
          },
        },
      ];
      expect(devfileResult.projects).toStrictEqual(expectedProjects);
    });

    test('existing projects matching git', async () => {
      const initialProjects = [
        {
          name: 'my-repo',
          git: {
            remotes: {
              origin: 'http://my.origin',
            },
            checkoutFrom: {
              revision: 'my-branch',
            },
          },
        },
      ];

      const devfileContent = jsYaml.dump({
        projects: initialProjects,
      });
      const projects = [
        {
          name: 'my-repo',
          location: 'http://my-another-location',
        },
      ];
      const main = new Main();
      const result = main.replaceIfExistingProjects(devfileContent, projects);
      const devfileResult = jsYaml.load(result);

      const expectedProjects = [];
      Object.assign(expectedProjects, initialProjects);
      expectedProjects[0].git.remotes.origin = 'http://my-another-location';
      expect(devfileResult.projects).toStrictEqual(expectedProjects);
    });
  });
});
