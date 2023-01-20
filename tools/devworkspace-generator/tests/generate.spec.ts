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

import fs from 'fs-extra';
import * as jsYaml from 'js-yaml';

import { Container } from 'inversify';
import { Generate } from '../src/generate';
import { DevContainerComponentFinder } from '../src/devfile/dev-container-component-finder';

describe('Test Generate', () => {
  let container: Container;

  let generate: Generate;

  let devContainerFinder: DevContainerComponentFinder;

  beforeEach(() => {
    jest.restoreAllMocks();
    jest.resetAllMocks();
    container = new Container();
    container.bind(Generate).toSelf().inSingletonScope();
    container.bind(DevContainerComponentFinder).toSelf().inSingletonScope();
    generate = container.get(Generate);
    devContainerFinder = container.get(DevContainerComponentFinder);
  });

  describe('Without writing an output file', () => {
    test('basics', async () => {
      const devfileContent = `
schemaVersion: 2.2.0
metadata:
  name: my-dummy-project
components:
  - name: dev-container
    mountSources: true
    container:
      image: quay.io/foo/bar
`;
      const editorContent = `
schemaVersion: 2.2.0
metadata:
  name: che-code
`;

      const fsWriteFileSpy = jest.spyOn(fs, 'writeFile');
      fsWriteFileSpy.mockReturnValue({});

      let context = await generate.generate(devfileContent, editorContent);
      // expect not to write the file
      expect(fsWriteFileSpy).not.toBeCalled();
      expect(JSON.stringify(context.devfile)).toStrictEqual(
        '{"schemaVersion":"2.2.0","metadata":{"name":"my-dummy-project"},"components":[{"name":"dev-container","mountSources":true,"container":{"image":"quay.io/foo/bar"},"attributes":{"controller.devfile.io/merge-contribution":true}}]}'
      );
      const expectedDevWorkspace = {
        apiVersion: 'workspace.devfile.io/v1alpha2',
        kind: 'DevWorkspace',
        metadata: { name: 'my-dummy-project' },
        spec: {
          started: true,
          template: {
            components: [
              {
                name: 'dev-container',
                mountSources: true,
                container: {
                  image: 'quay.io/foo/bar',
                },
                attributes: {
                  'controller.devfile.io/merge-contribution': true,
                },
              },
            ],
          },
          contributions: [{ name: 'editor', kubernetes: { name: 'che-code-my-dummy-project' } }],
        },
      };
      expect(JSON.stringify(context.devWorkspace)).toStrictEqual(JSON.stringify(expectedDevWorkspace));
      const expectedDevWorkspaceTemplates = [
        {
          apiVersion: 'workspace.devfile.io/v1alpha2',
          kind: 'DevWorkspaceTemplate',
          metadata: { name: 'che-code-my-dummy-project' },
          spec: {},
        },
      ];
      expect(JSON.stringify(context.devWorkspaceTemplates)).toStrictEqual(
        JSON.stringify(expectedDevWorkspaceTemplates)
      );
      expect(context.suffix).toStrictEqual('my-dummy-project');
    });
  });

  describe('With writing an output file', () => {
    test('basics', async () => {
      const devfileContent = `
schemaVersion: 2.2.0
metadata:
  name: my-dummy-project
components:
  - name: dev-container
    mountSources: true
    container:
      image: quay.io/foo/bar
`;
      const fakeoutputDir = '/fake-output';
      const editorContent = `
schemaVersion: 2.2.0
metadata:
  name: che-code
`;

      const fsWriteFileSpy = jest.spyOn(fs, 'writeFile');
      fsWriteFileSpy.mockReturnValue({});

      let context = await generate.generate(devfileContent, editorContent, fakeoutputDir);
      // expect to write the file
      expect(fsWriteFileSpy).toBeCalled();
      expect(JSON.stringify(context.devfile)).toStrictEqual(
        '{"schemaVersion":"2.2.0","metadata":{"name":"my-dummy-project"},"components":[{"name":"dev-container","mountSources":true,"container":{"image":"quay.io/foo/bar"},"attributes":{"controller.devfile.io/merge-contribution":true}}]}'
      );
      const expectedDevWorkspace = {
        apiVersion: 'workspace.devfile.io/v1alpha2',
        kind: 'DevWorkspace',
        metadata: { name: 'my-dummy-project' },
        spec: {
          started: true,
          template: {
            components: [
              {
                name: 'dev-container',
                mountSources: true,
                container: {
                  image: 'quay.io/foo/bar',
                },
                attributes: {
                  'controller.devfile.io/merge-contribution': true,
                },
              },
            ],
          },
          contributions: [{ name: 'editor', kubernetes: { name: 'che-code-my-dummy-project' } }],
        },
      };
      expect(JSON.stringify(context.devWorkspace)).toStrictEqual(JSON.stringify(expectedDevWorkspace));
      const expectedDevWorkspaceTemplates = [
        {
          apiVersion: 'workspace.devfile.io/v1alpha2',
          kind: 'DevWorkspaceTemplate',
          metadata: { name: 'che-code-my-dummy-project' },
          spec: {},
        },
      ];
      expect(JSON.stringify(context.devWorkspaceTemplates)).toStrictEqual(
        JSON.stringify(expectedDevWorkspaceTemplates)
      );
      expect(context.suffix).toStrictEqual('my-dummy-project');
    });

    test('add attribute', async () => {
      const devfileContent = `
schemaVersion: 2.2.0
metadata:
  name: my-dummy-project
components:
  - name: dev-container
    attributes:
      old: attribute
    mountSources: true
    container:
      image: quay.io/foo/bar
`;
      const fakeoutputDir = '/fake-output';
      const editorContent = `
schemaVersion: 2.2.0
metadata:
  name: che-code
`;

      const fsWriteFileSpy = jest.spyOn(fs, 'writeFile');
      fsWriteFileSpy.mockReturnValue({});

      let context = await generate.generate(devfileContent, editorContent, fakeoutputDir);
      // expect to write the file
      expect(fsWriteFileSpy).toBeCalled();
      expect(JSON.stringify(context.devfile)).toStrictEqual(
        '{"schemaVersion":"2.2.0","metadata":{"name":"my-dummy-project"},"components":[{"name":"dev-container","attributes":{"old":"attribute","controller.devfile.io/merge-contribution":true},"mountSources":true,"container":{"image":"quay.io/foo/bar"}}]}'
      );
      const expectedDevWorkspace = {
        apiVersion: 'workspace.devfile.io/v1alpha2',
        kind: 'DevWorkspace',
        metadata: { name: 'my-dummy-project' },
        spec: {
          started: true,
          template: {
            components: [
              {
                name: 'dev-container',
                attributes: {
                  old: 'attribute',
                  'controller.devfile.io/merge-contribution': true,
                },
                mountSources: true,
                container: {
                  image: 'quay.io/foo/bar',
                },
              },
            ],
          },
          contributions: [{ name: 'editor', kubernetes: { name: 'che-code-my-dummy-project' } }],
        },
      };
      expect(JSON.stringify(context.devWorkspace)).toStrictEqual(JSON.stringify(expectedDevWorkspace));
      const expectedDevWorkspaceTemplates = [
        {
          apiVersion: 'workspace.devfile.io/v1alpha2',
          kind: 'DevWorkspaceTemplate',
          metadata: { name: 'che-code-my-dummy-project' },
          spec: {},
        },
      ];
      expect(JSON.stringify(context.devWorkspaceTemplates)).toStrictEqual(
        JSON.stringify(expectedDevWorkspaceTemplates)
      );
      expect(context.suffix).toStrictEqual('my-dummy-project');
    });

    test('basics no name', async () => {
      const devfileContent = `
schemaVersion: 2.2.0
metadata:
 foo: bar
components:
  - name: dev-container
    mountSources: true
    container:
      image: quay.io/foo/bar
`;
      const fakeoutputDir = '/fake-output';
      const editorContent = `
schemaVersion: 2.1.0
metadata:
  name: che-code
`;

      const fsWriteFileSpy = jest.spyOn(fs, 'writeFile');
      fsWriteFileSpy.mockReturnValue({});

      let context = await generate.generate(devfileContent, editorContent, fakeoutputDir);
      // expect to write the file
      expect(fsWriteFileSpy).toBeCalled();
      expect(context.suffix).toStrictEqual('');
    });
  });
});
