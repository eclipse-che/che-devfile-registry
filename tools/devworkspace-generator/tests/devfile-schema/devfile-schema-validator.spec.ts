/**********************************************************************
 * Copyright (c) 2023 Red Hat, Inc.
 *
 * This program and the accompanying materials are made
 * available under the terms of the Eclipse Public License 2.0
 * which is available at https://www.eclipse.org/legal/epl-2.0/
 *
 * SPDX-License-Identifier: EPL-2.0
 ***********************************************************************/

/* eslint-disable @typescript-eslint/no-explicit-any */
import 'reflect-metadata';

import { Container } from 'inversify';
import { DevfileSchemaValidator } from '../../src/devfile-schema/devfile-schema-validator';
import * as path from 'path';
import * as fs from 'fs-extra';
import * as jsYaml from 'js-yaml';

describe('DevfileValidator', () => {
  let container: Container;
  let validator: DevfileSchemaValidator;

  beforeEach(() => {
    jest.restoreAllMocks();
    jest.resetAllMocks();
    container = new Container();
    container.bind(DevfileSchemaValidator).toSelf().inSingletonScope();
    validator = container.get(DevfileSchemaValidator);
  });

  test.each([
    ['2.0.0', 'empty-devfile.yaml'],
    ['2.1.0', 'empty-devfile.yaml'],
    ['2.2.0', 'empty-devfile.yaml'],
    ['2.2.1', 'empty-devfile.yaml'],
    ['2.2.2', 'empty-devfile.yaml'],
    ['2.3.0', 'empty-devfile.yaml'],
  ])('Valid empty devfile for schema %s', async (schemaVersion, fileName) => {
    const devfilePath = path.resolve(__dirname, '..', '_data', 'devfile', schemaVersion, fileName);
    const devfileYamlContent = await fs.readFile(devfilePath, 'utf-8');
    const devfile = jsYaml.load(devfileYamlContent);

    const result = validator.validateDevfile(devfile, schemaVersion);
    expect(result.valid).toBe(true);
  });

  test.each([
    ['2.0.0', 'ansible-devfile.yaml'],
    ['2.1.0', 'ansible-devfile.yaml'],
    ['2.2.0', 'ansible-devfile.yaml'],
  ])('Valid ansible devfile for schema %s', async (schemaVersion, fileName) => {
    const devfilePath = path.resolve(__dirname, '..', '_data', 'devfile', schemaVersion, fileName);
    const devfileYamlContent = await fs.readFile(devfilePath, 'utf-8');
    const devfile = jsYaml.load(devfileYamlContent);

    const result = validator.validateDevfile(devfile, schemaVersion);
    expect(result.valid).toBe(true);
  });

  test.each([
    ['2.0.0', 'quarkus-api-devfile.yaml'],
    ['2.1.0', 'quarkus-api-devfile.yaml'],
    ['2.2.0', 'quarkus-api-devfile.yaml'],
    ['2.2.1', 'quarkus-api-devfile.yaml'],
    ['2.2.2', 'quarkus-api-devfile.yaml'],
    ['2.3.0', 'quarkus-api-devfile.yaml'],
  ])('Valid quarkus api devfile for schema %s', async (schemaVersion, fileName) => {
    const devfilePath = path.resolve(__dirname, '..', '_data', 'devfile', schemaVersion, fileName);
    const devfileYamlContent = await fs.readFile(devfilePath, 'utf-8');
    const devfile = jsYaml.load(devfileYamlContent);

    const result = validator.validateDevfile(devfile, schemaVersion);
    expect(result.valid).toBe(true);
  });

  test('Invalid devfile without component type', async () => {
    const invalidDevfileYamlPath = path.resolve(__dirname, '..', '_data', 'devfile', 'invalid-devfile.yaml');
    const invalidDevfileYamlContent = await fs.readFile(invalidDevfileYamlPath, 'utf-8');
    const invalidDevfile = jsYaml.load(invalidDevfileYamlContent);

    const schema = '2.2.0';

    const result = validator.validateDevfile(invalidDevfile, schema);
    expect(result.valid).toBe(false);

    expect(result.toString()).toContain('0: instance.components[0] requires property "container"');
    expect(result.toString()).toContain('1: instance.components[0] requires property "kubernetes"');
    expect(result.toString()).toContain('2: instance.components[0] requires property "openshift"');
    expect(result.toString()).toContain('3: instance.components[0] requires property "volume"');
    expect(result.toString()).toContain('4: instance.components[0] requires property "image"');
    expect(result.toString()).toContain(
      '5: instance.components[0] is not exactly one from [subschema 0],[subschema 1],[subschema 2],[subschema 3],[subschema 4]'
    );
  });

  test('Invalid command in devfile', async () => {
    const invalidDevfileYamlPath = path.resolve(__dirname, '..', '_data', 'devfile', 'invalid-devfile-2.yaml');
    const invalidDevfileYamlContent = await fs.readFile(invalidDevfileYamlPath, 'utf-8');
    const invalidDevfile = jsYaml.load(invalidDevfileYamlContent);

    const schema = '2.2.0';

    const result = validator.validateDevfile(invalidDevfile, schema);
    expect(result.valid).toBe(false);

    expect(result.toString()).toContain('0: instance.commands[0].exec requires property "commandLine"');
    expect(result.toString()).toContain('1: instance.commands[0].exec requires property "component"');
  });

  it('should throw an error if the devfile version is not supported', () => {
    const devfile = {
      apiVersion: '3.0.0',
      metadata: {
        name: 'test-devfile',
      },
      components: [],
    };
    const version = '3.0.0';

    expect(() => validator.validateDevfile(devfile, version)).toThrowError(
      `Dev Workspace generator tool doesn't support devfile version: ${version}`
    );
  });
});
