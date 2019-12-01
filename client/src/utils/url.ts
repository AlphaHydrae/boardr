import { parse, stringify } from 'query-string';

export type UrlQueryParamValue = string | string[];

export interface UrlQueryParams {
  [key: string]: UrlQueryParamValue;
}

export function parseQuery(url: string | URL) {
  return parse(typeof url === 'string' ? url.replace(/^[^?]+/, '').replace(/#.*$/, '') : url.search) as UrlQueryParams;
}

export function stringifyQuery(params: UrlQueryParams) {
  return stringify(params);
}