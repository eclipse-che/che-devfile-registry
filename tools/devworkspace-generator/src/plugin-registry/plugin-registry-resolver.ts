/**********************************************************************
 * Copyright (c) 2022 Red Hat, Inc.
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 ***********************************************************************/

import * as jsYaml from 'js-yaml';

import { inject, injectable, named } from 'inversify';

import { UrlFetcher } from '../fetch/url-fetcher';

/**
 * Resolve plug-ins by grabbing the definition from the plug-in registry.
 */
@injectable()
export class PluginRegistryResolver {
  @inject('string')
  @named('PLUGIN_REGISTRY_URL')
  private pluginRegistryUrl: string;

  @inject(UrlFetcher)
  private urlFetcher: UrlFetcher;

  // FQN id (like eclipse/che-theia/next)
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  async loadDevfilePlugin(devfileId: string): Promise<any> {
    const devfileUrl = `${this.pluginRegistryUrl}/plugins/${devfileId}/devfile.yaml`;
    const devfileContent = await this.urlFetcher.fetchText(devfileUrl);
    return jsYaml.load(devfileContent);
  }
}
