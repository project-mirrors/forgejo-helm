import { readFileSync, writeFileSync } from 'node:fs';
import { isDeepStrictEqual } from 'node:util';
import prettier from 'prettier';
import YAML from 'yaml';

const valuesPath = 'values.yaml';
const schemaPath = 'values.schema.json';
const PARAM_RE = /^## @param\s+(\S+)\s+(.*)$/;

const args = new Set(process.argv.slice(2));
const check = args.has('--check');

main().catch((error) => {
  console.error(`Error: ${error.message}`);
  process.exit(1);
});

async function main() {
  const valuesSource = readRequiredFile(valuesPath);
  const values = YAML.parse(valuesSource);
  const metadata = parseMetadata(valuesSource);

  const schema = {
    $schema: 'https://json-schema.org/draft-07/schema#',
    title: 'Forgejo Helm chart values',
    type: 'object',
    additionalProperties: true,
    properties: buildObjectProperties(values, ''),
  };

  addExplicitTopLevelProperties(schema);
  applyMetadata(schema, metadata);
  applyOverrides(schema);

  const schemaJson = await prettier.format(JSON.stringify(schema), {
    parser: 'json',
  });

  if (check) {
    const current = readRequiredFile(schemaPath);
    if (current !== schemaJson) {
      throw new Error(
        `${schemaPath} is out of date. Run "pnpm schema" and commit the result.`,
      );
    }
  } else {
    writeFileSync(schemaPath, schemaJson);
  }
}

function readRequiredFile(path) {
  try {
    return readFileSync(path, 'utf8');
  } catch (error) {
    if (error.code === 'ENOENT') {
      throw new Error(`Required file "${path}" was not found.`);
    }
    throw new Error(`Unable to read "${path}": ${error.message}`);
  }
}

function parseMetadata(source) {
  const params = new Map();
  const deprecated = new Map();
  const pendingDeprecatedGuidance = [];

  for (const rawLine of source.split('\n')) {
    const line = rawLine.trim();

    if (line.startsWith('## @deprecated')) {
      pendingDeprecatedGuidance.length = 0;
      pendingDeprecatedGuidance.push(
        line.replace(/^## @deprecated\s*/, '').trim(),
      );
      continue;
    }

    if (pendingDeprecatedGuidance.length > 0 && line.startsWith('## -')) {
      pendingDeprecatedGuidance.push(line.replace(/^##\s*/, '').trim());
      continue;
    }

    const param = line.match(PARAM_RE);
    if (param) {
      const [, path, description] = param;
      params.set(path, description.trim());
      if (
        pendingDeprecatedGuidance.length > 0 ||
        /\bDEPRECATED\b/i.test(description)
      ) {
        deprecated.set(path, [...pendingDeprecatedGuidance]);
      }
      pendingDeprecatedGuidance.length = 0;
      continue;
    }

    if (pendingDeprecatedGuidance.length > 0 && line.startsWith('## @')) {
      pendingDeprecatedGuidance.length = 0;
      continue;
    }

    if (
      pendingDeprecatedGuidance.length > 0 &&
      line.startsWith('## ') &&
      !line.startsWith('## @')
    ) {
      pendingDeprecatedGuidance.push(line.replace(/^##\s*/, '').trim());
      continue;
    }

    if (!line.startsWith('##') && line !== '#') {
      pendingDeprecatedGuidance.length = 0;
    }
  }

  return { params, deprecated };
}

function buildObjectProperties(value, path) {
  return Object.fromEntries(
    Object.entries(value).map(([key, child]) => [
      key,
      schemaForValue(child, joinPath(path, key)),
    ]),
  );
}

function schemaForValue(value, path) {
  if (Array.isArray(value)) {
    const schema = { type: 'array' };
    if (value.length > 0) {
      schema.items = mergeArrayItemSchemas(
        value.map((item) => schemaForValue(item, `${path}[]`)),
      );
    } else {
      schema.items = {};
    }
    return schema;
  }

  if (value && typeof value === 'object') {
    return {
      type: 'object',
      additionalProperties: true,
      properties: buildObjectProperties(value, path),
    };
  }

  if (value === null) {
    return { type: ['string', 'null'] };
  }

  if (Number.isInteger(value)) {
    return { type: 'integer' };
  }

  if (typeof value === 'number') {
    return { type: 'number' };
  }

  if (typeof value === 'boolean') {
    return { type: 'boolean' };
  }

  return { type: 'string' };
}

function mergeArrayItemSchemas(schemas) {
  if (schemas.length === 0) {
    return {};
  }

  const [first, ...rest] = schemas;
  if (rest.every((schema) => isDeepStrictEqual(schema, first))) {
    return first;
  }

  const types = uniqueItems(
    schemas.flatMap((schema) =>
      Array.isArray(schema.type) ? schema.type : [schema.type],
    ),
  ).filter(Boolean);

  return types.length > 0 ? { type: types } : {};
}

function addExplicitTopLevelProperties(rootSchema) {
  rootSchema.properties.nameOverride = {
    type: 'string',
    description: 'String to partially override common.names.fullname.',
  };
  rootSchema.properties.fullnameOverride = {
    type: 'string',
    description: 'String to fully override common.names.fullname.',
  };
  rootSchema.properties.common = {
    type: 'object',
    additionalProperties: true,
    description: 'Values passed to the Bitnami common dependency chart.',
  };
}

function applyMetadata(rootSchema, { params, deprecated }) {
  for (const [path, description] of params.entries()) {
    const target = ensureSchemaPath(rootSchema, path);
    target.description = description;
  }

  for (const [path, guidance] of deprecated.entries()) {
    const target = ensureSchemaPath(rootSchema, path);
    target.deprecated = true;
    target.description = deprecatedDescription(
      params.get(path) ?? target.description ?? '',
      guidance,
    );
  }
}

function deprecatedDescription(description, guidance) {
  const cleanDescription = description
    .replace(/\*\*DEPRECATED\*\*/gi, '')
    .replace(/\bDEPRECATED:?/gi, '')
    .trim();
  const guidanceText = deprecatedGuidanceText(guidance);

  return ['DEPRECATED:', sentence(cleanDescription), guidanceText]
    .filter(Boolean)
    .join(' ');
}

function deprecatedGuidanceText(guidance) {
  const sentences = [];
  let currentSentence;
  let listItems = [];

  const flush = () => {
    if (!currentSentence) {
      return;
    }

    sentences.push(
      sentence(
        [currentSentence, listItems.join(', ')].filter(Boolean).join(' '),
      ),
    );
    currentSentence = undefined;
    listItems = [];
  };

  for (const line of guidance) {
    if (line.startsWith('- ')) {
      listItems.push(line.replace(/^- /, '').replace(/\.$/, ''));
      continue;
    }

    flush();
    currentSentence = line;
  }

  flush();
  return sentences.join(' ');
}

function sentence(text) {
  if (!text) {
    return '';
  }

  return /[.!?]$/.test(text) ? text : `${text}.`;
}

function applyOverrides(rootSchema) {
  const overrides = {
    'strategy.type': { enum: ['Recreate', 'RollingUpdate'] },
    'strategy.rollingUpdate.maxSurge': intOrStringOverride(),
    'strategy.rollingUpdate.maxUnavailable': intOrStringOverride(),
    'image.tag': { type: ['string', 'number'] },
    'image.pullPolicy': { enum: ['Always', 'IfNotPresent', 'Never'] },
    'service.http.type': serviceTypeOverride(),
    'service.ssh.type': serviceTypeOverride(),
    'service.http.externalTrafficPolicy': nullableEnum(['Cluster', 'Local']),
    'service.ssh.externalTrafficPolicy': nullableEnum(['Cluster', 'Local']),
    'service.http.ipFamilyPolicy': nullableEnum([
      'SingleStack',
      'PreferDualStack',
      'RequireDualStack',
    ]),
    'service.ssh.ipFamilyPolicy': nullableEnum([
      'SingleStack',
      'PreferDualStack',
      'RequireDualStack',
    ]),
    'service.http.externalIPs': nullableStringArrayOverride(),
    'service.ssh.externalIPs': nullableStringArrayOverride(),
    'service.http.ipFamilies': {
      type: ['array', 'null'],
      items: { type: 'string', enum: ['IPv4', 'IPv6'] },
    },
    'service.ssh.ipFamilies': {
      type: ['array', 'null'],
      items: { type: 'string', enum: ['IPv4', 'IPv6'] },
    },
    'ingress.hosts[].paths[].pathType': {
      enum: ['Exact', 'Prefix', 'ImplementationSpecific'],
    },
    'httpRoute.matches.path.type': {
      enum: ['Exact', 'PathPrefix', 'RegularExpression'],
    },
    'route.wildcardPolicy': nullableEnum(['None', 'Subdomain']),
    'route.tls.termination': nullableEnum(['edge', 'passthrough', 'reencrypt']),
    'route.tls.insecureEdgeTerminationPolicy': nullableEnum([
      'Allow',
      'Redirect',
      'None',
    ]),
    'gitea.admin.passwordMode': {
      enum: ['keepUpdated', 'initialOnlyNoReset', 'initialOnlyRequireReset'],
    },
    replicaCount: { minimum: 1 },
    'deployment.terminationGracePeriodSeconds': { minimum: 0 },
  };

  const portPaths = [
    'service.http.port',
    'service.http.nodePort',
    'service.ssh.port',
    'service.ssh.nodePort',
    'service.ssh.hostPort',
    'httpRoute.port',
    'tcpRoute.port',
  ];

  for (const path of portPaths) {
    overrides[path] = portOverride(path);
  }

  for (const probe of ['livenessProbe', 'readinessProbe', 'startupProbe']) {
    overrides[`gitea.${probe}.tcpSocket.port`] = intOrStringPortOverride();
    overrides[`gitea.${probe}.httpGet.port`] = intOrStringPortOverride();
    overrides[`gitea.${probe}.initialDelaySeconds`] = { minimum: 0 };
    overrides[`gitea.${probe}.timeoutSeconds`] = { minimum: 1 };
    overrides[`gitea.${probe}.periodSeconds`] = { minimum: 1 };
    overrides[`gitea.${probe}.successThreshold`] = { minimum: 1 };
    overrides[`gitea.${probe}.failureThreshold`] = { minimum: 1 };
  }

  for (const [path, override] of Object.entries(overrides)) {
    Object.assign(ensureSchemaPath(rootSchema, path), override);
  }

  Object.assign(ensureSchemaPath(rootSchema, 'gitea.config'), {
    type: 'object',
    additionalProperties: true,
  });
  loosenGiteaConfig(rootSchema);
}

function serviceTypeOverride() {
  return {
    type: 'string',
    enum: ['ClusterIP', 'NodePort', 'LoadBalancer', 'ExternalName'],
  };
}

function nullableEnum(values) {
  return {
    type: ['string', 'null'],
    enum: [...values, null],
  };
}

function nullableStringArrayOverride() {
  return {
    type: ['array', 'null'],
    items: { type: 'string' },
  };
}

function intOrStringOverride() {
  return {
    type: ['integer', 'string'],
  };
}

function portOverride(path) {
  return {
    type:
      path.endsWith('.port') && !path.includes('Route')
        ? 'integer'
        : ['integer', 'null'],
    minimum: 1,
    maximum: 65535,
  };
}

function intOrStringPortOverride() {
  return {
    type: ['integer', 'string'],
    minimum: 1,
    maximum: 65535,
  };
}

function loosenGiteaConfig(rootSchema) {
  const config = ensureSchemaPath(rootSchema, 'gitea.config');
  for (const property of Object.values(config.properties ?? {})) {
    if (property.type === 'object') {
      delete property.properties;
      property.additionalProperties = true;
    }
  }
}

function ensureSchemaPath(rootSchema, path) {
  const pathParts = Array.isArray(path)
    ? path
    : resolveSchemaPath(rootSchema, path);
  let current = rootSchema;

  for (const part of pathParts) {
    if (part === '[]') {
      current.items ??= {};
      current = current.items;
      continue;
    }

    current.properties ??= {};
    current.properties[part] ??= {};
    current = current.properties[part];
  }

  return current;
}

function resolveSchemaPath(rootSchema, path) {
  const tokens = tokenizePath(path);
  const parts = [];
  let current = rootSchema;
  let index = 0;

  while (index < tokens.length) {
    if (tokens[index] === '[]') {
      parts.push(tokens[index]);
      current = current.items ?? {};
      index += 1;
      continue;
    }

    const property = findLongestExistingProperty(current, tokens, index);
    if (property) {
      parts.push(property.name);
      current = current.properties?.[property.name] ?? {};
      index += property.consumed;
      continue;
    }

    const fallback = tokens[index];
    parts.push(fallback);
    current = current.properties?.[fallback] ?? {};
    index += 1;
  }

  return parts;
}

function findLongestExistingProperty(schema, tokens, startIndex) {
  const properties = schema.properties ?? {};

  for (let length = tokens.length - startIndex; length > 0; length -= 1) {
    const candidate = tokens.slice(startIndex, startIndex + length).join('.');
    if (Object.hasOwn(properties, candidate)) {
      return { name: candidate, consumed: length };
    }
  }

  return undefined;
}

function tokenizePath(path) {
  const tokens = [];
  for (const rawPart of path.split('.')) {
    const matches = rawPart.matchAll(/([^\[\]]+)|(\[\d*\])/g);
    for (const match of matches) {
      tokens.push(match[2] ? '[]' : match[1]);
    }
  }
  return tokens;
}

function joinPath(base, key) {
  return base ? `${base}.${key}` : key;
}

function uniqueItems(values) {
  return [...new Set(values)];
}
