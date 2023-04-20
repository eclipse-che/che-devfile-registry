/**********************************************************************
 * Copyright (c) 2022 Red Hat, Inc.
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 ***********************************************************************/

import { DevfileContext } from '../api/devfile-context';
import { V1alpha2DevWorkspaceSpecTemplateComponents } from '@devfile/api';
import { inject, injectable } from 'inversify';
import { DevContainerComponentInserter } from './dev-container-component-inserter';

/**
 * Need to find dev container from main dev workspace
 */
@injectable()
export class DevContainerComponentFinder {
  @inject(DevContainerComponentInserter)
  private devContainerComponentInserter: DevContainerComponentInserter;

  async find(
    devfileContext: DevfileContext,
    injectDefaultComponent?: string,
    defaultComponentImage?: string
  ): Promise<V1alpha2DevWorkspaceSpecTemplateComponents | undefined> {
    // if a devfile contains a parent, we should not add a default dev container
    if (devfileContext.devfile?.parent) {
      return undefined;
    }
    // search in main devWorkspace
    const devComponents = devfileContext.devWorkspace.spec?.template?.components
      ?.filter(component => component.container)
      .filter(
        // we should ignore component that do not mount the sources
        component => component.container && component.container.mountSources !== false
      );

    if (!devComponents || devComponents.length === 0) {
      // do not inject a default component if injectDefaultComponent parameter is false
      if (!injectDefaultComponent || injectDefaultComponent !== 'true') {
        return undefined;
      }
      this.devContainerComponentInserter.insert(devfileContext, defaultComponentImage);

      let devComponents = devfileContext.devWorkspace.spec.template.components.filter(component => component.container);

      return devComponents[0];
    } else if (devComponents.length === 1) {
      return devComponents[0];
    } else {
      console.warn(
        `More than one dev container component has been potentially found, taking the first one of ${devComponents.map(
          component => component.name
        )}`
      );
      return devComponents[0];
    }
  }
}
