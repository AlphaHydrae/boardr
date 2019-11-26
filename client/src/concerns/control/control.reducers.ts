import { constant } from 'lodash';
import { combineReducers } from 'redux';
import { reducerWithInitialState } from 'typescript-fsa-reducers';

import { loadSavedState } from '../../store/storage';
import { ControlState, initialControlState } from './control.state';

const readyReducer = reducerWithInitialState(initialControlState.ready)
  .case(loadSavedState, constant(true))
;

export const controlReducer = combineReducers<ControlState>({
  ready: readyReducer
});