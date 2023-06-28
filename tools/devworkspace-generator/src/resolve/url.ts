/**********************************************************************
 * Copyright (c) 2023 Red Hat, Inc.
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 ***********************************************************************/

/**
 * Url object
 */
export interface Url {
  /**
   * Provides RAW file content url
   * @param path file path
   */
  getContentUrl(path: string);

  /**
   * Provides repositories Url
   */
  getUrl(): string;

  /**
   * Provides Git clone url
   */
  getCloneUrl(): string;

  /**
   * Provides repository name
   */
  getRepoName(): string;

  /**
   * Provides branch name if initialised.
   */
  getBranchName(): string;
}
