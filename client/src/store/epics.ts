import { AnyAction } from 'redux';
import { combineEpics } from 'redux-observable';

import { AppState } from './state';

// tslint:disable-next-line: no-empty-interface
export interface AppEpicDependencies {
}

export const rootEpic = combineEpics<AnyAction, AnyAction, AppState, AppEpicDependencies>(
);