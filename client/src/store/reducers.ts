import { combineReducers } from 'redux';

import { communicationReducer } from '../concerns/comm/comm.reducers';
import { controlReducer } from '../concerns/control/control.reducers';
import { dataReducer } from '../concerns/data/data.reducers';
import { routerReducer } from '../concerns/router/router.reducers';
import { sessionReducer } from '../concerns/session/session.reducers';
import { AppState } from './state';

export const rootReducer = combineReducers<AppState>({
  communication: communicationReducer,
  control: controlReducer,
  data: dataReducer,
  router: routerReducer,
  session: sessionReducer
});