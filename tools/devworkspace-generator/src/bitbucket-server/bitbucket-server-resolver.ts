/**********************************************************************
 * Copyright (c) 2023 Red Hat, Inc.
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 ***********************************************************************/

import { BitbucketServerUrl } from './bitbucket-server-url';
import { injectable } from 'inversify';
import { Url } from '../resolve/url';
import { Resolver } from '../resolve/resolver';

@injectable()
export class BitbucketServerResolver implements Resolver {
  // eslint-disable-next-line max-len
  static readonly BITBUCKET_URL_PATTERNS: RegExp[] = [
    /^(?<scheme>https?):\/\/(?<host>.*)\/scm\/~(?<user>[^\/]+)\/(?<repo>.*).git$/,
    /^(?<scheme>https?):\/\/(?<host>.*)\/users\/(?<user>[^\/]+)\/repos\/(?<repo>[^\/]+)\/browse(\?at=(?<branch>.*))?$/,
    /^(?<scheme>https?):\/\/(?<host>.*)\/scm\/(?<project>[^\/~]+)\/(?<repo>[^\/]+).git$/,
    /^(?<scheme>https?):\/\/(?<host>.*)\/projects\/(?<project>[^\/]+)\/repos\/(?<repo>[^\/]+)\/browse(\?at=(?<branch>.*))?$/,
  ];

  isValid(url: string): boolean {
    return BitbucketServerResolver.BITBUCKET_URL_PATTERNS.some(p => p.test(url));
  }

  resolve(url: string): Url {
    const regExp = BitbucketServerResolver.BITBUCKET_URL_PATTERNS.find(p => p.test(url));
    if (!regExp) {
      throw new Error(`Invalid bitbucket-server URL: ${url}`);
    }
    const match = regExp.exec(url);
    const scheme = this.getGroup(match, 'scheme');
    const hostName = this.getGroup(match, 'host');
    const user = this.getGroup(match, 'user');
    const project = this.getGroup(match, 'project');
    const repo = this.getGroup(match, 'repo');
    let branch = this.getGroup(match, 'branch');
    if (branch !== undefined && branch.startsWith('refs%2Fheads%2F')) {
      branch = branch.substring(15);
    }
    return new BitbucketServerUrl(scheme, hostName, user, project, repo, branch);
  }

  private getGroup(match: RegExpExecArray, groupName: string): string | undefined {
    if (match.groups && match.groups[groupName]) {
      return match.groups[groupName];
    }
  }
}
