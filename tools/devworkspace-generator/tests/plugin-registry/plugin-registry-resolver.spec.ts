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

import * as jsYaml from 'js-yaml';

import { Container } from 'inversify';
import { PluginRegistryResolver } from '../../src/plugin-registry/plugin-registry-resolver';
import { UrlFetcher } from '../../src/fetch/url-fetcher';

describe('Test PluginRegistryResolver', () => {
  let container: Container;

  const originalConsoleError = console.error;
  const mockedConsoleError = jest.fn();

  const urlFetcherFetchTextMock = jest.fn();
  const urlFetcherFetchTextOptionalMock = jest.fn();
  const urlFetcher = {
    fetchText: urlFetcherFetchTextMock,
    fetchTextOptionalContent: urlFetcherFetchTextOptionalMock,
  } as any;

  let pluginRegistryResolver: PluginRegistryResolver;

  beforeEach(() => {
    jest.restoreAllMocks();
    jest.resetAllMocks();
    container = new Container();
    container.bind(PluginRegistryResolver).toSelf().inSingletonScope();
    container.bind(UrlFetcher).toConstantValue(urlFetcher);
    container.bind('string').toConstantValue('http://fake-plugin-registry').whenTargetNamed('PLUGIN_REGISTRY_URL');
    pluginRegistryResolver = container.get(PluginRegistryResolver);
    console.error = mockedConsoleError;
  });

  afterEach(() => {
    console.error = originalConsoleError;
  });

  test('basic loadDevfilePlugin', async () => {
    const myId = 'foo';
    const dummy = { dummyContent: 'dummy' };
    urlFetcherFetchTextMock.mockResolvedValue(jsYaml.dump(dummy));
    const content = await pluginRegistryResolver.loadDevfilePlugin(myId);
    expect(urlFetcherFetchTextMock).toBeCalledWith('http://fake-plugin-registry/plugins/foo/devfile.yaml');
    expect(content).toStrictEqual(dummy);
  });
});
