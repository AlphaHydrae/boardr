import { combineReducers } from 'redux';
import { reducerWithInitialState } from 'typescript-fsa-reducers';

import { initialSessionState, SessionState } from './session.state';

export const sessionReducer = combineReducers<SessionState>({
  foo: reducerWithInitialState(initialSessionState.foo)
});