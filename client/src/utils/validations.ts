import { constant } from 'lodash';

export interface RequiredValidation {
  readonly required: boolean;
}

export function isBlank(value: unknown) {
  return typeof value === 'string' && value.match(/^\s*$/) !== null;
}

export function isJson(value: unknown, predicate: (parsed: unknown) => boolean = constant(true)) {
  if (typeof value !== 'string') {
    return false;
  }

  try {
    return predicate(JSON.parse(value));
  } catch (_) {
    return false;
  }
}

export function isNotUndefined<T>(value: T | undefined): value is T {
  return value !== undefined;
}

export function isPresent(value: unknown) {
  return typeof value === 'string' && !value.match(/^\s*$/);
}

export function isUrlString(value: unknown, protocols: string[]): value is string {
  if (typeof value !== 'string') {
    return false;
  }

  try {
    const url = new URL(value);
    return protocols.includes(url.protocol);
  } catch (err) {
    return false;
  }
}