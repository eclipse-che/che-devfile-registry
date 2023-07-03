/**********************************************************************
 * Copyright (c) 2023 Red Hat, Inc.
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 ***********************************************************************/
import { injectable, multiInject } from 'inversify';
import { Url } from './url';
import { TYPES } from '../types';
import { Resolver } from './resolver';

const { Resolver } = TYPES;

@injectable()
export class GitUrlResolver {
  @multiInject(Resolver)
  private resolvers: Resolver[];

  resolve(link: string): Url {
    const resolver = this.resolvers.find(r => r.isValid(link));
    if (resolver) {
      return resolver.resolve(link);
    } else {
      throw new Error('Can not resolver the URL');
    }
  }
}
