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

export class BitbucketServerUrl implements Url {
  constructor(
    private readonly scheme: string,
    private readonly hostName: string,
    private readonly user: string | undefined,
    private readonly project: string | undefined,
    private readonly repo: string,
    private readonly branch: string | undefined
  ) {}

  getContentUrl(path: string): string {
    const isUser = this.user !== undefined;
    return `${this.scheme}://${this.hostName}/${isUser ? 'users' : 'projects'}/${
      isUser ? this.user : this.project
    }/repos/${this.repo}/raw/${path}${this.branch !== undefined ? '?/at=' + this.branch : ''}`;
  }

  getUrl(): string {
    const isUser = this.user !== undefined;
    return `${this.scheme}://${this.hostName}/${isUser ? 'users' : 'projects'}/${
      isUser ? this.user : this.project
    }/repos/${this.repo}${this.branch !== undefined ? '/browse?at=' + this.branch : ''}`;
  }

  getCloneUrl(): string {
    const isUser = this.user !== undefined;
    return `${this.scheme}://${this.hostName}/scm/${isUser ? '~' + this.user : this.project.toLowerCase()}/${
      this.repo
    }.git`;
  }

  getRepoName(): string {
    return this.repo;
  }

  getBranchName(): string {
    return this.branch;
  }
}
