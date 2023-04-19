/**********************************************************************
 * Copyright (c) 2023 Red Hat, Inc.
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
import { DevContainerComponentInserter } from '../../src/devfile/dev-container-component-inserter';
import { DevfileContext } from '../../src/api/devfile-context';

describe('Test DevContainerComponentInserter', () => {
  let container: Container;

  let devContainerComponentInserter: DevContainerComponentInserter;

  beforeEach(() => {
    jest.restoreAllMocks();
    jest.resetAllMocks();
    container = new Container();
    container.bind(DevContainerComponentInserter).toSelf().inSingletonScope();
    devContainerComponentInserter = container.get(DevContainerComponentInserter);
  });

  test('insert default component', async () => {
    const devfileContext = {
      devWorkspace: {},
    } as DevfileContext;

    const defaultImage = 'quay.io/devfile/universal-developer-image:ubi8-latest';

    await devContainerComponentInserter.insert(devfileContext);
    const devContainer = devfileContext.devWorkspace.spec?.template?.components?.[0];

    expect(devfileContext.devWorkspace.spec?.template?.components?.length).toBe(1);
    expect(devContainer?.name).toBe('dev');
    expect(devContainer?.container?.image).toBe(defaultImage);
  });

  test('insert dev component with custom image', async () => {
    const devfileContext = {
      devWorkspace: {},
    } as DevfileContext;

    await devContainerComponentInserter.insert(devfileContext, 'my-image');
    const devContainer = devfileContext.devWorkspace.spec?.template?.components?.[0];

    expect(devfileContext.devWorkspace.spec?.template?.components?.length).toBe(1);
    expect(devContainer?.name).toBe('dev');
    expect(devContainer?.container?.image).toBe('my-image');
  });
});
