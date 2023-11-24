/**********************************************************************
 * Copyright (c) 2023 Red Hat, Inc.
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 ***********************************************************************/
import { injectable } from 'inversify';

import * as devfileSchemaV200 from './2.0.0/devfile.json';
import * as devfileSchemaV210 from './2.1.0/devfile.json';
import * as devfileSchemaV220 from './2.2.0/devfile.json';
import * as devfileSchemaV221 from './2.2.1/devfile.json';
import * as devfileSchemaV222 from './2.2.2/devfile.json';
import * as Validator from 'jsonschema';
import { DevfileSchemaVersion } from '../api/devfile-context';

@injectable()
export class DevfileSchemaValidator {
  getDevfileSchema(version: string) {
    switch (version) {
      case DevfileSchemaVersion.V200:
        return devfileSchemaV200;
      case DevfileSchemaVersion.V210:
        return devfileSchemaV210;
      case DevfileSchemaVersion.V220:
        return devfileSchemaV220;
      case DevfileSchemaVersion.V221:
        return devfileSchemaV221;
      case DevfileSchemaVersion.V222:
        return devfileSchemaV222;
      default:
        throw new Error(`Dev Workspace generator tool doesn't support devfile version: ${version}`);
    }
  }

  // Validates devfile against schema
  validateDevfile(devfile: any, version: string) {
    const schema = this.getDevfileSchema(version);
    const validatorResult = Validator.validate(devfile, schema, { nestedErrors: true });

    return validatorResult;
  }
}
