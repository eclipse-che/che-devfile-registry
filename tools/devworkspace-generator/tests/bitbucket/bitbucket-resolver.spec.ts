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
import { BitbucketResolver } from '../../src/bitbucket/bitbucket-resolver';

describe('Test Bitbucket resolver', () => {
  let container: Container;

  let bitbucketResolver: BitbucketResolver;

  const BITBUCKET_URL = 'https://bitbucket.org/workspace/repo';

  beforeEach(() => {
    jest.restoreAllMocks();
    jest.resetAllMocks();
    container = new Container();
    container.bind(BitbucketResolver).toSelf().inSingletonScope();
    bitbucketResolver = container.get(BitbucketResolver);
  });

  test('test get Url', async () => {
    const array = [
      ['https://user@bitbucket.org/workspace/repo.git', 'https://bitbucket.org/workspace/repo/src/HEAD'],
      [BITBUCKET_URL, 'https://bitbucket.org/workspace/repo/src/HEAD'],
      [BITBUCKET_URL + '/', 'https://bitbucket.org/workspace/repo/src/HEAD'],
      [BITBUCKET_URL + '/src/branch', 'https://bitbucket.org/workspace/repo/src/branch'],
      [BITBUCKET_URL + '/src/branch/', 'https://bitbucket.org/workspace/repo/src/branch'],
    ];
    array.forEach(a => expect(bitbucketResolver.resolve(a[0]).getUrl()).toBe(a[1]));
  });

  test('test get clone Url', async () => {
    const url = 'https://bitbucket.org/workspace/repo.git';
    const array = [
      ['https://user@bitbucket.org/workspace/repo.git', url],
      [BITBUCKET_URL, url],
      [BITBUCKET_URL + '/', url],
      [BITBUCKET_URL + '/src/branch', url],
      [BITBUCKET_URL + '/src/branch/', url],
    ];
    array.forEach(a => expect(bitbucketResolver.resolve(a[0]).getCloneUrl()).toBe(a[1]));
  });

  test('test get content Url', async () => {
    const url = 'https://bitbucket.org/workspace/repo/raw/HEAD/Readme.md';
    const array = [
      ['https://user@bitbucket.org/workspace/repo.git', url],
      [BITBUCKET_URL, url],
      [BITBUCKET_URL + '/', url],
      [BITBUCKET_URL + '/src/branch', 'https://bitbucket.org/workspace/repo/raw/branch/Readme.md'],
      [BITBUCKET_URL + '/src/branch/', 'https://bitbucket.org/workspace/repo/raw/branch/Readme.md'],
    ];
    array.forEach(a => expect(bitbucketResolver.resolve(a[0]).getContentUrl('Readme.md')).toBe(a[1]));
  });

  test('test get branch', async () => {
    expect(bitbucketResolver.resolve('https://bitbucket.org/workspace/repo/src/branch').getBranchName()).toBe('branch');
    expect(bitbucketResolver.resolve('https://bitbucket.org/workspace/repo/src/branch/').getBranchName()).toBe(
      'branch'
    );
  });

  test('test get repository', async () => {
    const array = [
      'https://user@bitbucket.org/workspace/repo.git',
      BITBUCKET_URL,
      BITBUCKET_URL + '/',
      BITBUCKET_URL + '/src/branch',
      BITBUCKET_URL + '/src/branch/',
    ];
    array.forEach(a => expect(bitbucketResolver.resolve(a).getRepoName()).toBe('repo'));
  });

  test('validate URL', async () => {
    const array = [
      'https://user@bitbucket.org/workspace/repo.git',
      BITBUCKET_URL,
      BITBUCKET_URL + '/',
      BITBUCKET_URL + '/src/branch',
      BITBUCKET_URL + '/src/branch/',
    ];
    array.forEach(a => expect(bitbucketResolver.isValid(a)).toBeTruthy());
    expect(bitbucketResolver.isValid('https://github.com/user/repo')).toBeFalsy();
  });

  test('error', async () => {
    expect(() => {
      bitbucketResolver.resolve('http://unknown/che');
    }).toThrow('Invalid bitbucket URL:');
  });
});
