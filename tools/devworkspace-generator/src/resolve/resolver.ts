/**********************************************************************
 * Copyright (c) 2023 Red Hat, Inc.
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 ***********************************************************************/

import { Url } from './url';

export interface Resolver {
  /**
   * Validates the string url for belonging to a specific Git provider.
   * @param url string representation of Url.
   */
  isValid(url: string): boolean;

  /**
   * Resolves repository string URL to a {@class Url} object.
   * @param url string representation of Url.
   */
  resolve(url: string): Url;
}
