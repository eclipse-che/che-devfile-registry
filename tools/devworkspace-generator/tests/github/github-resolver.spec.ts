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

import { Container } from 'inversify';
import { GithubResolver } from '../../src/github/github-resolver';

describe('Test PluginRegistryResolver', () => {
  let container: Container;

  let githubResolver: GithubResolver;

  const GITHUB_URL = 'https://github.com/eclipse/che';

  beforeEach(() => {
    jest.restoreAllMocks();
    jest.resetAllMocks();
    container = new Container();
    container.bind(GithubResolver).toSelf().inSingletonScope();
    githubResolver = container.get(GithubResolver);
  });

  test('test get Url', async () => {
    const url = 'https://github.com/eclipse/che/tree/HEAD/';
    const array = [
      [GITHUB_URL, url],
      [GITHUB_URL + '/', url],
      [GITHUB_URL + '.git', url],
      [GITHUB_URL + '/tree/7.30.x', 'https://github.com/eclipse/che/tree/7.30.x/'],
    ];
    array.forEach(a => expect(githubResolver.resolve(a[0]).getUrl()).toBe(a[1]));
  });

  test('test get clone Url', async () => {
    const url = 'https://github.com/eclipse/che.git';
    const array = [
      [GITHUB_URL, url],
      [GITHUB_URL + '/', url],
      [GITHUB_URL + '.git', url],
      [GITHUB_URL + '/tree/7.30.x', url],
    ];
    array.forEach(a => expect(githubResolver.resolve(a[0]).getCloneUrl()).toBe(a[1]));
  });

  test('test get content Url', async () => {
    const url = 'https://raw.githubusercontent.com/eclipse/che/HEAD/README.md';
    const array = [
      [GITHUB_URL, url],
      [GITHUB_URL + '/', url],
      [GITHUB_URL + '.git', url],
      [GITHUB_URL + '/tree/7.30.x', 'https://raw.githubusercontent.com/eclipse/che/7.30.x/README.md'],
      ['https://github.mycompany.net/user/repo', 'https://raw.github.mycompany.net/user/repo/HEAD/README.md'],
    ];
    array.forEach(a => expect(githubResolver.resolve(a[0]).getContentUrl('README.md')).toBe(a[1]));
  });

  test('test get branch', async () => {
    expect(githubResolver.resolve(GITHUB_URL + '/tree/7.30.x').getBranchName()).toBe('7.30.x');
    expect(githubResolver.resolve(GITHUB_URL + '/tree/7.30.x/').getBranchName()).toBe('7.30.x');
  });

  test('test get repository', async () => {
    const array = [
      GITHUB_URL,
      GITHUB_URL + '/',
      GITHUB_URL + '.git',
      GITHUB_URL + '/tree/7.30.x',
      'https://github.mycompany.net/user/che',
    ];
    array.forEach(a => expect(githubResolver.resolve(a).getRepoName()).toBe('che'));
  });

  test('validate URL', async () => {
    const array = [
      GITHUB_URL,
      GITHUB_URL + '/',
      GITHUB_URL + '.git',
      GITHUB_URL + '/tree/7.30.x',
      'https://github.mycompany.net/user/che',
    ];
    array.forEach(a => expect(githubResolver.isValid(a)).toBeTruthy());
    expect(githubResolver.isValid('http://unknown/che')).toBeFalsy();
  });

  test('error', async () => {
    expect(() => {
      githubResolver.resolve('http://unknown/che');
    }).toThrow('Invalid github URL:');
  });
});
