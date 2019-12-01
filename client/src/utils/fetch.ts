import { reduce } from 'lodash';
import { Observable, Observer } from 'rxjs';

import { emptyRecord } from './generic';
import { parseQuery, stringifyQuery } from './url';

export interface ApiError {
  readonly message: string;
  readonly response?: ApiResponse;
}

export interface ApiRequest {
  readonly headers?: Record<string, string>;
  readonly body?: any;
  readonly method?: string;
  readonly query?: Record<string, string | string[] | undefined>;
  readonly url: string;
}

export interface ApiResponse {
  readonly headers: Record<string, string>;
  readonly body?: any;
  readonly status: number;
}

class ResponseError extends Error {
  constructor(message: string, readonly response?: Response) {
    super(message);
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

export function fetchApiObservable(req: ApiRequest): Observable<ApiResponse> {
  return new Observable((observer: Observer<ApiResponse>) => {
    Promise.resolve().then(() => fetchApi(req)).then(res => {
      observer.next(res);
      observer.complete();
    }).catch(err => observer.error(err));
  });
}

export async function serializeApiError(err: any): Promise<ApiError> {
  if (!(err instanceof Error)) {
    return {
      message: 'An unexpected error occurred'
    };
  } else if (!(err instanceof ResponseError)) {
    return {
      message: err.message
    };
  }

  return {
    message: err.message,
    response: err.response ? await serializeResponse(err.response, true) : undefined
  };
}

async function fetchApi(req: ApiRequest): Promise<ApiResponse> {

  const headers = new Headers(req.headers || {});
  if (!headers.get('Accept')) {
    headers.set('Accept', 'application/json');
  }

  let body;
  if (req.body !== undefined) {

    const contentType = headers.get('Content-Type');
    if (contentType !== null && !mediaTypeIsJson(contentType)) {
      throw new Error(`Property "jsonValue" cannot be used with content type "${contentType}"`);
    } else if (contentType === null) {
      headers.set('Content-Type', 'application/json');
    }

    body = JSON.stringify(req.body);
  }

  const url = updateUrlQuery(req.url, req.query);

  const response = await fetch(url, {
    body,
    headers,
    method: req.method
  });

  if (response.status < 200 || response.status > 299) {
    throw new ResponseError(`Server responded with unexpected status code ${response.status}`, response);
  }

  return serializeResponse(response);
}

function mediaTypeIsJson(message: string | Request | Response | null) {
  const contentType = message === null || typeof message === 'string' ? message : message.headers.get('Content-Type');
  return contentType !== null && (contentType.match(/^application\/json/) !== null || contentType.match(/\+json(?:;|$)/)) !== null;
}

function serializeHeaders(headers?: Headers) {

  const serialized = emptyRecord<string>();
  if (!headers) {
    return serialized;
  }

  headers.forEach((value, key) => {
    serialized[key] = value;
  });

  return serialized;
}

async function serializeResponse(response: Response, ignoreErrors = false): Promise<ApiResponse> {

  let body;
  if (response.body && mediaTypeIsJson(response)) {
    try {
      body = await response.json();
    } catch (err) {
      if (!ignoreErrors) {
        throw new ResponseError(err instanceof Error ? err.message : 'An unexpected error occurred', response);
      }
    }
  }

  return {
    body,
    headers: serializeHeaders(response.headers),
    status: response.status
  };
}

function updateUrlQuery(url: string, query?: Record<string, string | string[] | undefined>) {
  if (!query) {
    return url;
  }

  const combinedQuery = {
    ...parseQuery(url),
    ...reduce(
      query,
      (memo, value, key) => value !== undefined ? ({
        ...memo,
        [key]: value
      }) : memo,
      emptyRecord<string | string[]>()
    )
  };

  return `${url.replace(/(?:\?[^#]*)?(?:#[^#]*)?$/, `?${stringifyQuery(combinedQuery)}`)}`;
}