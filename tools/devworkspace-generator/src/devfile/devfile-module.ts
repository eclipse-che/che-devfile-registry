/**********************************************************************
 * Copyright (c) 2022 Red Hat, Inc.
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 ***********************************************************************/
import { ContainerModule, interfaces } from 'inversify';

import { DevContainerComponentFinder } from './dev-container-component-finder';
import { DevContainerComponentInserter } from './dev-container-component-inserter';

const devfileModule = new ContainerModule((bind: interfaces.Bind) => {
  bind(DevContainerComponentFinder).toSelf().inSingletonScope();
  bind(DevContainerComponentInserter).toSelf().inSingletonScope();
});

export { devfileModule };
