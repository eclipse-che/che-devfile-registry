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

import { Container, injectable } from 'inversify';
import { GitUrlResolver } from '../../src/resolve/git-url-resolver';
import { TYPES } from '../../src/types';

describe('Test git Url resolver', () => {
  let container: Container;

  let urlResolver: GitUrlResolver;

  const resolveMock = jest.fn();
  const isValidMock = jest.fn();
  const resolver = {
    resolve: resolveMock,
    isValid: isValidMock,
  } as any;

  beforeEach(() => {
    jest.restoreAllMocks();
    jest.resetAllMocks();
    container = new Container();
    container.bind(GitUrlResolver).toSelf().inSingletonScope();
    container.bind(TYPES.Resolver).toConstantValue(resolver);
    urlResolver = container.get(GitUrlResolver);
  });

  test('test url resolver', async () => {
    isValidMock.mockReturnValue(true);

    urlResolver.resolve('test');

    expect(resolveMock).toBeCalledWith('test');
  });

  test('test resolver failure', async () => {
    isValidMock.mockReturnValue(false);

    expect(() => urlResolver.resolve('test')).toThrow('Can not resolver the URL');
  });
});
