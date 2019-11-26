import { combineReducers } from 'redux';
import { reducerWithInitialState } from 'typescript-fsa-reducers';

import { DataState, initialDataState } from './data.state';

export const dataReducer = combineReducers<DataState>({
  foo: reducerWithInitialState(initialDataState.foo)
});