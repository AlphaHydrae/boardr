import { connectRouter } from 'connected-react-router';

import { history } from '../../store/history';

export const routerReducer = connectRouter(history);