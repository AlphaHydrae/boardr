import localforage from 'localforage';
import { debounce, pick } from 'lodash';
import { Middleware } from 'redux';

import { initialSessionState } from '../concerns/session/session.state';
import { storageDebounceTime, storageKey } from '../constants';
import { decode } from '../utils/codecs';
import { createAction } from '../utils/store';
import { SavedStateCodec } from './codecs';
import { AppState, SavedState } from './state';

export const loadSavedState = createAction<SavedState>('LOAD_SAVED_STATE');

export function createStorageLoadingMiddleware(): Middleware {
  return store => {

    Promise
      .resolve()
      .then(loadState)
      .then(savedState => store.dispatch(loadSavedState(savedState)))
      .catch(err => console.warn(err));

    return next => next;
  };
}

export function createStorageMiddleware(): Middleware {
  return store => next => action => {

    const result = next(action);

    Promise
      .resolve(store.getState())
      .then(debounce(saveState, storageDebounceTime, { leading: true }))
      .catch(err => console.warn(err));

    return result;
  };
}

async function loadState(): Promise<SavedState> {
  const value = await localforage.getItem(storageKey);
  return decode(SavedStateCodec, value) || { session: initialSessionState };
}

async function saveState(state: AppState) {
  if (!state.control.ready) {
    return;
  }

  const stateToSave = getStateToSave(state);
  await localforage.setItem(storageKey, stateToSave);
}

function getStateToSave(state: AppState): SavedState {
  return pick(state, 'session');
}