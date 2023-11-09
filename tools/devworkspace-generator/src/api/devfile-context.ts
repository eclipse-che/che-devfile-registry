/**********************************************************************
 * Copyright (c) 2022 Red Hat, Inc.
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 ***********************************************************************/
import { V1alpha2DevWorkspace, V1alpha2DevWorkspaceTemplate } from '@devfile/api';

/**
 * Context used on every call to this service to update DevWorkspace
 */
export interface DevfileContext {
  // devfile Content
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  devfile: any;

  // devWorkspace
  devWorkspace: V1alpha2DevWorkspace;

  // devWorkspace templates
  devWorkspaceTemplates: V1alpha2DevWorkspaceTemplate[];

  // suffix to append on generated names
  suffix: string;
}

/**
 * Enum for Devfile schema versions
 */
export enum DevfileSchemaVersion {
  V200 = '2.0.0',
  V210 = '2.1.0',
  V220 = '2.2.0',
  V221_alpha = '2.2.1-alpha',
}
