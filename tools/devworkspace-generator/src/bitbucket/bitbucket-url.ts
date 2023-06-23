/**********************************************************************
 * Copyright (c) 2023 Red Hat, Inc.
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 ***********************************************************************/

import { Url } from '../resolve/url';

export class BitbucketUrl implements Url {
  private static readonly BITBUCKET_URL = 'https://bitbucket.org';

  constructor(
    private readonly workspaceId: string,
    private readonly repoName: string,
    private readonly branchName: string
  ) {}

  getContentUrl(path: string): string {
    return `${BitbucketUrl.BITBUCKET_URL}/${this.workspaceId}/${this.repoName}/raw/${this.branchName}/${path}`;
  }

  getUrl(): string {
    return `${BitbucketUrl.BITBUCKET_URL}/${this.workspaceId}/${this.repoName}/src/${this.branchName}`;
  }

  getCloneUrl(): string {
    return `${BitbucketUrl.BITBUCKET_URL}/${this.workspaceId}/${this.repoName}.git`;
  }

  getRepoName(): string {
    return this.repoName;
  }

  getBranchName(): string {
    return this.branchName;
  }
}
