import { Action } from 'redux';
import { StateObservable } from 'redux-observable';
import { Observable } from 'rxjs';
import { actionCreatorFactory, AsyncActionCreators } from 'typescript-fsa';

import { ActionType } from '../store/actions';
import { AppEpicDependencies } from '../store/epics';
import { AppState } from '../store/state';

export type Epic = (
  action$: Observable<Action>,
  state$: StateObservable<AppState>,
  dependencies: AppEpicDependencies
) => Observable<Action>;

export const createEpic = (func: Epic) => func;

const factory = actionCreatorFactory();
const registeredActionTypes: string[] = [];

export const registeredAsyncActions: Array<AsyncActionCreators<any, any, any>> = [];

export const createAction = <Payload = void>(type: ActionType) => {
  return factory<Payload>(registerActionType(type));
};

export const createAsyncAction = <Params, Result, Error>(type: ActionType) => {

  const action = factory.async<Params, Result, Error>(registerActionType(type));
  registeredAsyncActions.push(action);

  return action;
};

export function serializeError(err: unknown) {
  if (typeof err === 'string') {
    return {
      message: err
    };
  } else if (err instanceof DOMException) {
    return {
      code: err.code,
      message: err.message,
      name: err.name
    };
  } else if (err instanceof Error) {
    return {
      message: err.message,
      name: err.name,
      stack: err.stack
    };
  }

  return {
    message: JSON.stringify(err)
  };
}

function registerActionType(type: string) {
  if (registeredActionTypes.includes(type)) {
    throw new Error(`Action type "${type}" has already been registered`);
  }

  registeredActionTypes.push(type);
  return type;
}