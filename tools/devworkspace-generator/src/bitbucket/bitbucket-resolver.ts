/**********************************************************************
 * Copyright (c) 2023 Red Hat, Inc.
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 ***********************************************************************/

import { BitbucketUrl } from './bitbucket-url';
import { injectable } from 'inversify';
import { Url } from '../resolve/url';
import { Resolver } from '../resolve/resolver';

@injectable()
export class BitbucketResolver implements Resolver {
  // eslint-disable-next-line max-len
  static readonly BITBUCKET_URL_PATTERN: RegExp =
    /^https:\/\/.*@?bitbucket\.org\/(?<workspaceId>[^\/]+)\/(?<repoName>[^\/]+)(\/(src|branch)\/(?<branchName>[^\/]+))?\/?$/;

  isValid(url: string): boolean {
    return BitbucketResolver.BITBUCKET_URL_PATTERN.test(url);
  }

  resolve(url: string): Url {
    const match = BitbucketResolver.BITBUCKET_URL_PATTERN.exec(url);
    if (!match) {
      throw new Error(`Invalid bitbucket URL: ${url}`);
    }
    const workspaceId = this.getGroup(match, 'workspaceId');
    let repoName = this.getGroup(match, 'repoName');
    if (/^[\w-][\w.-]*?\.git$/.test(repoName)) {
      repoName = repoName.substring(0, repoName.length - 4);
    }
    const branchName = this.getGroup(match, 'branchName', 'HEAD');
    return new BitbucketUrl(workspaceId, repoName, branchName);
  }

  private getGroup(match: RegExpExecArray, groupName: string, defaultValue?: string) {
    if (match.groups && match.groups[groupName]) {
      return match.groups[groupName];
    }
    return defaultValue;
  }
}
