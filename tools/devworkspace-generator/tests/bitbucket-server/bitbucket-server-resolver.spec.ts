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
import { BitbucketServerResolver } from '../../src/bitbucket-server/bitbucket-server-resolver';

describe('Test Bitbucket resolver', () => {
  let container: Container;

  let bitbucketResolver: BitbucketServerResolver;

  const BITBUCKET_SERVER_URL = 'https://custom-bitbucket.com/';

  beforeEach(() => {
    jest.restoreAllMocks();
    jest.resetAllMocks();
    container = new Container();
    container.bind(BitbucketServerResolver).toSelf().inSingletonScope();
    bitbucketResolver = container.get(BitbucketServerResolver);
  });

  test('test get Url', async () => {
    const userUrl = BITBUCKET_SERVER_URL + 'users/user/repos/repo';
    const projectUrl = BITBUCKET_SERVER_URL + 'projects/project/repos/repo';
    const array = [
      [BITBUCKET_SERVER_URL + 'scm/~user/repo.git', userUrl],
      [BITBUCKET_SERVER_URL + 'users/user/repos/repo/browse', userUrl],
      [BITBUCKET_SERVER_URL + 'scm/project/repo.git', projectUrl],
      [BITBUCKET_SERVER_URL + 'projects/project/repos/repo/browse', projectUrl],
      [
        BITBUCKET_SERVER_URL + 'users/user/repos/repo/browse?at=branch',
        BITBUCKET_SERVER_URL + 'users/user/repos/repo/browse?at=branch',
      ],
      [
        BITBUCKET_SERVER_URL + 'users/user/repos/repo/browse?at=refs%2Fheads%2Fbranch',
        BITBUCKET_SERVER_URL + 'users/user/repos/repo/browse?at=branch',
      ],
      [
        BITBUCKET_SERVER_URL + 'projects/project/repos/repo/browse?at=branch',
        BITBUCKET_SERVER_URL + 'projects/project/repos/repo/browse?at=branch',
      ],
    ];
    array.forEach(a => expect(bitbucketResolver.resolve(a[0]).getUrl()).toBe(a[1]));
  });

  test('test get clone Url', async () => {
    const userUrl = BITBUCKET_SERVER_URL + 'scm/~user/repo.git';
    const projectUrl = BITBUCKET_SERVER_URL + 'scm/project/repo.git';
    const array = [
      [BITBUCKET_SERVER_URL + 'scm/~user/repo.git', userUrl],
      [BITBUCKET_SERVER_URL + 'users/user/repos/repo/browse', userUrl],
      [BITBUCKET_SERVER_URL + 'scm/project/repo.git', projectUrl],
      [BITBUCKET_SERVER_URL + 'projects/project/repos/repo/browse', projectUrl],
      [BITBUCKET_SERVER_URL + 'users/user/repos/repo/browse?at=branch', userUrl],
      [BITBUCKET_SERVER_URL + 'users/user/repos/repo/browse?at=refs%2Fheads%2Fbranch', userUrl],
      [BITBUCKET_SERVER_URL + 'projects/project/repos/repo/browse?at=branch', projectUrl],
    ];
    array.forEach(a => expect(bitbucketResolver.resolve(a[0]).getCloneUrl()).toBe(a[1]));
  });

  test('test get content', async () => {
    const userUrl = BITBUCKET_SERVER_URL + 'users/user/repos/repo/raw/README.md';
    const projectUrl = BITBUCKET_SERVER_URL + 'projects/project/repos/repo/raw/README.md';
    const array = [
      [BITBUCKET_SERVER_URL + 'scm/~user/repo.git', userUrl],
      [BITBUCKET_SERVER_URL + 'users/user/repos/repo/browse', userUrl],
      [BITBUCKET_SERVER_URL + 'scm/project/repo.git', projectUrl],
      [BITBUCKET_SERVER_URL + 'projects/project/repos/repo/browse', projectUrl],
      [
        BITBUCKET_SERVER_URL + 'users/user/repos/repo/browse?at=branch',
        BITBUCKET_SERVER_URL + 'users/user/repos/repo/raw/README.md?/at=branch',
      ],
      [
        BITBUCKET_SERVER_URL + 'users/user/repos/repo/browse?at=refs%2Fheads%2Fbranch',
        BITBUCKET_SERVER_URL + 'users/user/repos/repo/raw/README.md?/at=branch',
      ],
      [
        BITBUCKET_SERVER_URL + 'projects/project/repos/repo/browse?at=branch',
        BITBUCKET_SERVER_URL + 'projects/project/repos/repo/raw/README.md?/at=branch',
      ],
    ];
    array.forEach(a => expect(bitbucketResolver.resolve(a[0]).getContentUrl('README.md')).toBe(a[1]));
  });

  test('test get branch', async () => {
    expect(
      bitbucketResolver.resolve(BITBUCKET_SERVER_URL + 'users/user/repos/repo/browse?at=branch').getBranchName()
    ).toBe('branch');
    expect(
      bitbucketResolver
        .resolve(BITBUCKET_SERVER_URL + 'users/user/repos/repo/browse?at=refs%2Fheads%2Fbranch')
        .getBranchName()
    ).toBe('branch');
    expect(
      bitbucketResolver.resolve(BITBUCKET_SERVER_URL + 'projects/project/repos/repo/browse?at=branch').getBranchName()
    ).toBe('branch');
  });

  test('test get repository', async () => {
    const array = [
      BITBUCKET_SERVER_URL + 'scm/~user/repo.git',
      BITBUCKET_SERVER_URL + 'users/user/repos/repo/browse',
      BITBUCKET_SERVER_URL + 'scm/project/repo.git',
      BITBUCKET_SERVER_URL + 'projects/project/repos/repo/browse',
      BITBUCKET_SERVER_URL + 'users/user/repos/repo/browse?at=branch',
      BITBUCKET_SERVER_URL + 'users/user/repos/repo/browse?at=refs%2Fheads%2Fbranch',
      BITBUCKET_SERVER_URL + 'projects/project/repos/repo/browse?at=branch',
    ];
    array.forEach(a => expect(bitbucketResolver.resolve(a).getRepoName()).toBe('repo'));
  });

  test('validate URL', async () => {
    const array = [
      BITBUCKET_SERVER_URL + 'scm/~user/repo.git',
      BITBUCKET_SERVER_URL + 'users/user/repos/repo/browse',
      BITBUCKET_SERVER_URL + 'scm/project/repo.git',
      BITBUCKET_SERVER_URL + 'projects/project/repos/repo/browse',
      BITBUCKET_SERVER_URL + 'users/user/repos/repo/browse?at=branch',
      BITBUCKET_SERVER_URL + 'projects/project/repos/repo/browse?at=branch',
    ];
    array.forEach(a => expect(bitbucketResolver.isValid(a)).toBeTruthy());
    expect(bitbucketResolver.isValid('https://github.com/user/repo')).toBeFalsy();
  });

  test('error', async () => {
    expect(() => {
      bitbucketResolver.resolve('http://unknown/che');
    }).toThrow('Invalid bitbucket-server URL:');
  });
});
