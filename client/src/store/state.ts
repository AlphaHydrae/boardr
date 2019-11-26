import { RouterState } from 'connected-react-router';

import { CommunicationState, initialCommunicationState } from '../concerns/comm/comm.state';
import { ControlState, initialControlState } from '../concerns/control/control.state';
import { DataState, initialDataState } from '../concerns/data/data.state';
import { initialRouterState } from '../concerns/router/router.state';
import { initialSessionState, SessionState } from '../concerns/session/session.state';

export interface AppState {
  readonly communication: CommunicationState;
  readonly control: ControlState;
  readonly data: DataState;
  readonly router: RouterState;
  readonly session: SessionState;
}

export type SavedState = Pick<AppState, 'session'>;

export const initialAppState: AppState = {
  communication: initialCommunicationState,
  control: initialControlState,
  data: initialDataState,
  router: initialRouterState,
  session: initialSessionState
};