import { RouterState } from 'connected-react-router';

import { history } from '../../store/history';

export const initialRouterState: RouterState = {
  action: history.action,
  location: history.location
};