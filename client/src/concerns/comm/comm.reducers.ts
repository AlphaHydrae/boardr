import { reducerWithInitialState } from 'typescript-fsa-reducers';

import { registeredAsyncActions } from '../../utils/store';
import { initialCommunicationState } from './comm.state';
import { completionActionHasSameParams, getCompletionCreators, isCompletionAction } from './comm.utils';

export const communicationReducer = reducerWithInitialState(initialCommunicationState)

  .casesWithAction(
    registeredAsyncActions.map(creator => creator.started),
    (state, action) => [ ...state, action ]
  )

  .casesWithAction(
    getCompletionCreators(registeredAsyncActions),
    (state, action) => state.filter(
      ongoing => !isCompletionAction(ongoing, action) || !completionActionHasSameParams(ongoing, action)
    )
  )

;