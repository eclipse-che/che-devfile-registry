/**********************************************************************
 * Copyright (c) 2021 Red Hat, Inc.
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 ***********************************************************************/
/* eslint-disable @typescript-eslint/no-explicit-any */
import 'reflect-metadata';

import { Container } from 'inversify';
import { DevContainerComponentFinder } from '../../src/devfile/dev-container-component-finder';
import { DevfileContext } from '../../src/api/devfile-context';
import { DevContainerComponentInserter } from '../../src/devfile/dev-container-component-inserter';

describe('Test DevContainerComponentFinder', () => {
  let container: Container;

  let devContainerComponentFinder: DevContainerComponentFinder;

  let originalConsoleWarn = console.warn;

  beforeEach(() => {
    jest.restoreAllMocks();
    jest.resetAllMocks();
    container = new Container();
    container.bind(DevContainerComponentFinder).toSelf().inSingletonScope();
    container.bind(DevContainerComponentInserter).toSelf().inSingletonScope();
    devContainerComponentFinder = container.get(DevContainerComponentFinder);
    container.get(DevContainerComponentInserter);
    console.warn = jest.fn();
  });

  afterEach(() => {
    console.warn = originalConsoleWarn;
  });

  test('basics', async () => {
    const devfileContext = {
      devWorkspace: {
        spec: {
          template: {
            components: [
              { name: 'foo' },
              {
                name: 'che-code',
              },
              {
                name: 'my-container',
                container: {
                  image: 'user-image:123',
                },
              },
            ],
          },
        },
      },
    } as DevfileContext;
    const devWorkspaceSpecTemplateComponents = await devContainerComponentFinder.find(devfileContext);
    expect(devWorkspaceSpecTemplateComponents?.name).toBe('my-container');
  });

  test('only one container without mountSources:false', async () => {
    const devfileContext = {
      devWorkspace: {
        spec: {
          template: {
            components: [
              {
                name: 'container-with-mount-sources-false',
                container: {
                  mountSources: false,
                  image: 'user-image:123',
                },
              },
              {
                name: 'my-container',
                container: {
                  image: 'user-image:123',
                },
              },
            ],
          },
        },
      },
    } as DevfileContext;
    const devWorkspaceSpecTemplateComponents = await devContainerComponentFinder.find(devfileContext);
    expect(devWorkspaceSpecTemplateComponents.name).toBe('my-container');
  });

  test('missing dev container without devfile.parent', async () => {
    const devfileContext = {
      devfile: {},
      devWorkspace: {
        spec: {
          template: {
            components: [
              { name: 'foo' },
              {
                name: 'che-code',
              },
            ],
          },
        },
      },
    } as DevfileContext;
    const devWorkspaceSpecTemplateComponents = await devContainerComponentFinder.find(devfileContext);
    // default dev component is added
    expect(devfileContext.devWorkspace.spec?.template?.components?.length).toBe(2);
    expect(devWorkspaceSpecTemplateComponents?.name).toBe(undefined);
  });

  test('dev container should be injected with custom image', async () => {
    const devfileContext = {
      devfile: {},
      devWorkspace: {
        spec: {
          template: {
            components: [
              { name: 'foo' },
              {
                name: 'che-code',
              },
            ],
          },
        },
      },
    } as DevfileContext;
    const devWorkspaceSpecTemplateComponents = await devContainerComponentFinder.find(
      devfileContext,
      'true',
      'my-image'
    );
    // default dev component is added with custom image
    expect(devfileContext.devWorkspace.spec?.template?.components?.length).toBe(3);
    expect(devWorkspaceSpecTemplateComponents?.name).toBe('dev');
    expect(devWorkspaceSpecTemplateComponents?.container?.image).toBe('my-image');
  });

  test('dev container should be injected with a default image', async () => {
    const devfileContext = {
      devfile: {},
      devWorkspace: {
        spec: {
          template: {
            components: [
              { name: 'foo' },
              {
                name: 'che-code',
              },
            ],
          },
        },
      },
    } as DevfileContext;
    const devWorkspaceSpecTemplateComponents = await devContainerComponentFinder.find(devfileContext, 'true');
    // default dev component is added with a default image
    const defaultImage = 'quay.io/devfile/universal-developer-image:ubi8-latest';
    expect(devfileContext.devWorkspace.spec?.template?.components?.length).toBe(3);
    expect(devWorkspaceSpecTemplateComponents?.name).toBe('dev');
    expect(devWorkspaceSpecTemplateComponents?.container?.image).toBe(defaultImage);
  });

  test('missing dev container with devfile.parent', async () => {
    const devfileContext = {
      devfile: {
        parent: {
          id: 'java-maven',
          registryUrl: 'https://registry.stage.devfile.io/',
          version: '1.2.0',
        },
      },
      devWorkspace: {
        spec: {
          template: {
            components: [
              { name: 'foo' },
              {
                name: 'che-code',
              },
            ],
          },
        },
      },
    } as DevfileContext;
    const devWorkspaceSpecTemplateComponents = await devContainerComponentFinder.find(devfileContext);
    expect(devWorkspaceSpecTemplateComponents).toBeUndefined();
  });

  test('missing dev container (no components)', async () => {
    const devfileContext = {
      devfile: {},
      devWorkspace: {},
    } as DevfileContext;
    let devWorkspaceSpecTemplateComponents = await devContainerComponentFinder.find(devfileContext);
    expect(devWorkspaceSpecTemplateComponents?.name).toBe(undefined);
  });

  test('take first one when many dev container', async () => {
    const devfileContext = {
      devWorkspace: {
        spec: {
          template: {
            components: [
              { name: 'foo' },
              {
                name: 'che-code',
              },
              {
                name: 'my-container-1',
                container: {
                  image: 'user-image:123',
                },
              },
              {
                name: 'my-container-2',
                container: {
                  image: 'user-image:123',
                },
              },
            ],
          },
        },
      },
    } as DevfileContext;
    const devWorkspaceSpecTemplateComponents = await devContainerComponentFinder.find(devfileContext);
    expect(devWorkspaceSpecTemplateComponents?.name).toBe('my-container-1');
    expect(console.warn).toBeCalledWith(
      'More than one dev container component has been potentially found, taking the first one of my-container-1,my-container-2'
    );
  });
});
