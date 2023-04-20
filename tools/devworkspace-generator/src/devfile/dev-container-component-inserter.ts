/**********************************************************************
 * Copyright (c) 2023 Red Hat, Inc.
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 ***********************************************************************/

import { DevfileContext } from '../api/devfile-context';
import { V1alpha2DevWorkspaceSpecTemplateComponents } from '@devfile/api';
import { injectable } from 'inversify';

/**
 * Adds a new component on empty devfile with specific name and image
 */
@injectable()
export class DevContainerComponentInserter {
  readonly DEFAULT_DEV_CONTAINER_IMAGE = 'quay.io/devfile/universal-developer-image:ubi8-latest';
  readonly DEFAULT_DEV_CONTAINER_NAME = 'dev';

  async insert(devfileContext: DevfileContext, defaultComponentImage?: string): Promise<void> {
    if (!devfileContext.devWorkspace.spec) {
      devfileContext.devWorkspace.spec = {
        started: true,
      };
    }
    if (!devfileContext.devWorkspace.spec.template) {
      devfileContext.devWorkspace.spec.template = {};
    }
    if (!devfileContext.devWorkspace.spec.template.components) {
      devfileContext.devWorkspace.spec.template.components = [];
    }

    const devContainerImage = defaultComponentImage ? defaultComponentImage : this.DEFAULT_DEV_CONTAINER_IMAGE;
    console.log(
      `No container component has been found. A default container component with image ${devContainerImage} will be added.`
    );
    const devContainerComponent: V1alpha2DevWorkspaceSpecTemplateComponents = {
      name: this.DEFAULT_DEV_CONTAINER_NAME,
      container: {
        image: devContainerImage,
      },
    };

    devfileContext.devWorkspace.spec.template.components.push(devContainerComponent);
  }
}
